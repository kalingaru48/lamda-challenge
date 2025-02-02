// Handle GET /tasks
async function handleGetRequest(client, Sentry) {
    //manually start a span
    return Sentry.startSpan({ name: "get_tasks" }, async () => {
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
            console.error('Error fetching tasks:', error);
            return {
                statusCode: 500,
                body: JSON.stringify({ message: 'Internal Server Error' }),
            };
        }
    });
}

module.exports = {
    handleGetRequest,
};