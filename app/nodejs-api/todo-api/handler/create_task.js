// Handle POST /tasks
async function handlePostRequest(event, client, splunkLogger) {
    try {
        // Parse the incoming JSON payload
        const body = JSON.parse(event.body);
        const { title, description } = body;

        if (!title || !description) {
            splunkLogger.send("Title and description are required", "error");
            return {
                statusCode: 400,
                body: JSON.stringify({ message: 'Title and description are required' }),
            };
        }

        // Insert the task into the database
        const query = 'INSERT INTO tasks (title, description) VALUES ($1, $2) RETURNING *';
        const result = await client.query(query, [title, description]);
        splunkLogger.send("Task created successfully.", "info");

        // Return the created task
        return {
            statusCode: 201,
            body: JSON.stringify(result.rows[0]),
        };
    } catch (error) {
        console.error('Error creating task:', error);
        splunkLogger.send(`Error creating task: ${error.message}`, "error");
        return {
            statusCode: 500,
            body: JSON.stringify({ message: 'Internal Server Error' }),
        };
    }
}

module.exports = {
    handlePostRequest,
};