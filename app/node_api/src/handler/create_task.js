// Handle POST /tasks
async function handlePostRequest(event, client) {
    try {
      // Parse the incoming JSON payload
      const body = JSON.parse(event.body);
      const { description } = body;
  
      if (!description) {
        return {
          statusCode: 400,
          body: JSON.stringify({ message: 'Description is required' }),
        };
      }
  
      // Insert the task into the database
      const query = 'INSERT INTO tasks (description) VALUES ($1) RETURNING *';
      const result = await client.query(query, [description]);
  
      // Return the created task
      return {
        statusCode: 201,
        body: JSON.stringify(result.rows[0]),
      };
    } catch (error) {
      throw error;
    }
  }

module.exports = {
    handlePostRequest,
};
