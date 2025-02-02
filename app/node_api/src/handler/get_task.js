// Handle GET /tasks
async function handleGetRequest(client) {
    try {
      // Fetch all tasks from the database
      const query = 'SELECT * FROM tasks ORDER BY created_at DESC';
      const result = await client.query(query);
  
      // Return the list of tasks
      return {
        statusCode: 200,
        body: JSON.stringify(result.rows),
      };
    } catch (error) {
      throw error;
    }
  }

module.exports = {
    handleGetRequest,
};