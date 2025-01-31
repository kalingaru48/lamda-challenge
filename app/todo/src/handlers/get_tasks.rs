use lambda_http::{Body, Request, Response};
use sqlx::{PgPool, Row}; // Added Row trait import
use anyhow::Result;
use crate::models::task::Task;


pub async fn get_tasks(_req: Request, pool: &PgPool) -> Result<Response<Body>> {
    let tasks = sqlx::query(
        "SELECT id, title, description, completed FROM tasks"
    )
    .try_map(|row: sqlx::postgres::PgRow| {
        Ok(Task {
            id: row.try_get("id")?,
            title: row.try_get("title")?,
            description: row.try_get("description")?,
            completed: row.try_get("completed")?,
        })
    })
    .fetch_all(pool)
    .await?;
    let response = Response::builder()
        .status(200)
        .body(Body::from(serde_json::to_string(&tasks)?))?;
    
    Ok(response)
}