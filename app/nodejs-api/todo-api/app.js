const { runMigration } = require('./migrations/create_tasks_table');
const { handleGetRequest } = require('./handler/get_task');
const { handlePostRequest } = require('./handler/create_task');
const { Client } = require('pg');
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const Sentry = require("@sentry/aws-serverless");
const { nodeProfilingIntegration } = require("@sentry/profiling-node");
const SplunkLogger = require("./utils/splunklog");

// AWS Secrets Manager Setup
const secretsClient = new SecretsManagerClient({ region: process.env.AWS_REGION });
let cachedSecrets = null;
let splunkLogger = null;

/**
 * Fetch secrets from AWS Secrets Manager
 */
async function getSecretValue(secretName) {
    try {
        console.log(`Fetching secret: ${secretName}`);
        const response = await secretsClient.send(new GetSecretValueCommand({ SecretId: secretName }));

        if (!response.SecretString) {
            throw new Error(`Secret ${secretName} is empty`);
        }

        let secretData;
        try {
            secretData = JSON.parse(response.SecretString);
        } catch (error) {
            secretData = response.SecretString;
        }

        return secretData;
    } catch (error) {
        console.error(`Error retrieving secret (${secretName}):`, error);
        if (splunkLogger) splunkLogger.send(`Error retrieving secret: ${secretName}`, "error");
        throw new Error(`Failed to retrieve secret: ${secretName}`);
    }
}

/**
 * Initialize and cache secrets
 */
async function initializeSecrets() {
    if (cachedSecrets) return cachedSecrets;

    try {
        const dbSecret = await getSecretValue("rds-db-pwd");
        const sentrySecret = await getSecretValue("sentry-dsn-v1");
        const splunkSecret = await getSecretValue("splunk-hec-secret");

        cachedSecrets = {
            dbPassword: dbSecret?.password || process.env.DB_PASSWORD,
            sentryDsn: sentrySecret?.dsn || process.env.SENTRY_DSN,
            splunkToken: splunkSecret?.token || process.env.SPLUNK_HEC_TOKEN,
            splunkUrl: process.env.SPLUNK_HEC_URL
        };

        // Initialize SplunkLogger once
        splunkLogger = new SplunkLogger(cachedSecrets.splunkToken, cachedSecrets.splunkUrl);

        return cachedSecrets;
    } catch (error) {
        console.error("Failed to retrieve secrets from Secrets Manager, falling back to environment variables.");
        if (splunkLogger) splunkLogger.send("Failed to retrieve secrets from Secrets Manager, falling back to environment variables.", "warn");

        return {
            dbPassword: process.env.DB_PASSWORD,
            sentryDsn: process.env.SENTRY_DSN,
            splunkToken: process.env.SPLUNK_HEC_TOKEN,
            splunkUrl: process.env.SPLUNK_HEC_URL
        };
    }
}

exports.handler = Sentry.wrapHandler(async (event, context) => {
    let client = null;

    try {
        const secrets = await initializeSecrets();

        if (!secrets.dbPassword || !secrets.sentryDsn || !secrets.splunkToken) {
            console.error("Secrets not initialized properly.");
            if (splunkLogger) splunkLogger.send("Secrets not initialized properly.", "error");

            return { statusCode: 500, body: JSON.stringify({ message: "Secrets not initialized" }) };
        }

        // Initialize Sentry
        Sentry.init({
            dsn: secrets.sentryDsn,
            integrations: [nodeProfilingIntegration()],
            tracesSampleRate: 1.0,
        });

        Sentry.profiler.startProfiler();

        // Setup database connection
        client = new Client({
            host: process.env.DB_HOST,
            port: process.env.DB_PORT,
            user: process.env.DB_USER,
            password: secrets.dbPassword,
            database: process.env.DB_NAME,
            ssl: { rejectUnauthorized: false }
        });

        console.log("Connecting to the database...");
        await client.connect();
        console.log("Connected successfully!");
        if (splunkLogger) splunkLogger.send("Connected to the database successfully.", "info");

        // Handle migrations
        if (process.env.ENABLE_MIGRATION === 'true') {
            console.log("Running migration...");
            await runMigration(client);
        } else {
            console.log("Migration is disabled.");
        }

        const method = event.requestContext?.http?.method || event.httpMethod;
        let response;
        if (method === 'POST') {
            response = await handlePostRequest(event, client, splunkLogger);
        } else if (method === 'GET') {
            response = await handleGetRequest(client, splunkLogger);
        } else {
            response = { statusCode: 405, body: JSON.stringify({ message: "Method Not Allowed" }) };
        }

        if (splunkLogger) splunkLogger.send(`Lambda executed: ${method}`, "info");
        return response;

    } catch (error) {
        console.error(error);
        if (splunkLogger) splunkLogger.send(`${error.message}`, "error");
        Sentry.captureException(error);
        return { statusCode: 500, body: JSON.stringify({ message: "Internal Server Error!" }) };

    } finally {
        if (client) {
            await client.end();
            console.log("Database connection closed.");
        }
        Sentry.profiler.stopProfiler();
    }
}); 