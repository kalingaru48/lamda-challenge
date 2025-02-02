const createTableQuery = `
    CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
`;

async function runMigration(client) {
    try {
        await client.query(createTableQuery);
        console.log('Migration ran successfully');
    } catch (error) {
        console.error('Error running migration:', error);
    }
}

exports.runMigration = runMigration;