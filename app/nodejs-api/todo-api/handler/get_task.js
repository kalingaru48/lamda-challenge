// Handle GET /tasks
async function handleGetRequest(client, sendLogsToSplunk) {

        try {
            // Fetch all tasks from the database
            const query = 'SELECT * FROM tasks ORDER BY created_at DESC';
            const result = await client.query(query);

            sendLogsToSplunk("Tasks fetched successfully.", "info");
            // Return the list of tasks
            return {
                statusCode: 200,
                body: JSON.stringify(result.rows),
            };
        } catch (error) {
            console.error('Error fetching tasks:', error);
            sendLogsToSplunk(`Error fetching tasks: ${error.message}`, "error");
            return {
                statusCode: 500,
                body: JSON.stringify({ message: 'Internal Server Error' }),
            };
        }
}

module.exports = {
    handleGetRequest,
};