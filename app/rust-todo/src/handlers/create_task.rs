// src/handlers/create_task.rs
use lambda_http::{Body, Request, Response};
use uuid::Uuid;
use crate::models::task::{CreateTaskRequest, Task};
use sqlx::PgPool;
use anyhow::Result;

pub async fn create_task(req: Request, pool: &PgPool) -> Result<Response<Body>> {
    let task_req: CreateTaskRequest = serde_json::from_slice(req.body())?;
    
    let task = Task {
        id: Uuid::new_v4(),
        title: task_req.title,
        description: task_req.description,
        completed: false,
    };

    sqlx::query(
        "INSERT INTO tasks (id, title, description, completed) VALUES ($1, $2, $3, $4)"
    )
    .bind(task.id)
    .bind(&task.title)
    .bind(&task.description)
    .bind(task.completed)
    .execute(pool)
    .await?;

    let response = Response::builder()
        .status(201)
        .body(Body::from(serde_json::to_string(&task)?))?;
    
    Ok(response)
}