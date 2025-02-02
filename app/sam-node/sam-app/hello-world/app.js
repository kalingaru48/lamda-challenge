const { runMigration } = require('./migrations/create_tasks_table');
const { handleGetRequest } = require('./handler/get_task');
const { handlePostRequest } = require('./handler/create_task');
const { Client } = require('pg');

const Sentry = require("@sentry/aws-serverless");
const { nodeProfilingIntegration } = require("@sentry/profiling-node");

var SplunkLogger = require("splunk-logging").Logger;

// Splunk HEC configuration (use environment variables for flexibility)
const splunkConfig = {
  token: process.env.SPLUNK_HEC_TOKEN,  // Ensure this environment variable is set
  url: process.env.SPLUNK_HEC_URL,     // Ensure this environment variable is set
};

// Initialize Splunk Logger
var Logger = new SplunkLogger(splunkConfig);

Sentry.init({
  dsn: "https://6a95465f6196ed9480131a74791f320d@o4508744322383872.ingest.us.sentry.io/4508744337260544",
  integrations: [
    nodeProfilingIntegration(),
  ],
  tracesSampleRate: 1.0, // Capture 100% of transactions
});

Sentry.profiler.startProfiler();

exports.lambdaHandler = Sentry.wrapHandler(async (event, context) => {

  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    await client.connect();

    if (process.env.ENABLE_MIGRATION === 'true') {
      await runMigration(client);
    } else {
      console.log('Migration is disabled');
      // Send log to Splunk
      sendToSplunk('Migration is disabled');
    }

    let response;
    if (event.httpMethod === 'POST') {
      response = await handlePostRequest(event, client, Sentry);
    } else if (event.httpMethod === 'GET') {
      response = await handleGetRequest(client, Sentry);
    } else {
      response = {
        statusCode: 405,
        body: JSON.stringify({ message: 'Method Not Allowed' }),
      };
    }

    // Send response log to Splunk
    sendToSplunk(`Response sent: ${JSON.stringify(response)}`);

    return response;
  } catch (error) {
    Sentry.captureException(error);
    sendToSplunk(`Error occurred: ${error.message}`);

    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal Server Error' }),
    };
  } finally {
    await client.end();
    Sentry.profiler.stopProfiler();
  }
});

// Function to send logs to Splunk
function sendToSplunk(message) {
  const payload = {
    message: message, // Here you can adjust to send any custom message
  };

  console.log("Sending payload to Splunk:", payload);
  Logger.send(payload, (err, resp, body) => {
    if (err) {
      console.error('Error sending to Splunk:', err);
    } else {
      console.log('Response from Splunk:', body);
    }
  });
}
