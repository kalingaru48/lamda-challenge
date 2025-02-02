const { handleGetRequest } = require('./handler/get_task');
const { handlePostRequest } = require('./handler/create_task');
const { Client } = require('pg');
const Sentry = require('@sentry/node');



// Initialize Sentry for error monitoring
Sentry.init({
  dsn: 'YOUR_SENTRY_DSN', // Replace with your Sentry DSN
});

exports.handler = async (event) => {
  
  const client = new Client({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  try {
    // Connect to the database
    await client.connect();

    // Route based on HTTP method
    if (event.httpMethod === 'POST') {
      return await handlePostRequest(event, client);
    } else if (event.httpMethod === 'GET') {
      return await handleGetRequest(client);
    } else {
      return {
        statusCode: 405,
        body: JSON.stringify({ message: 'Method Not Allowed' }),
      };
    }
  } catch (error) {
    // Capture the error in Sentry
    Sentry.captureException(error);

    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Internal Server Error' }),
    };
  } finally {
    // Ensure the database connection is closed
    await client.end();
  }
};


