use lambda_http::{run, service_fn, Body, Error, Request, Response};
use opentelemetry::global;
use opentelemetry_sdk::Resource;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, fmt};
use sqlx::PgPool;
use opentelemetry_otlp::WithExportConfig;

mod db;
mod models;
mod handlers;

use handlers::{create_task::create_task, get_tasks::get_tasks};

async fn function_handler(req: Request, pool: &PgPool) -> Result<Response<Body>, Error> {
    match (req.method().as_str(), req.uri().path()) {
        ("POST", "/tasks") => Ok(create_task(req, pool).await?),
        ("GET", "/tasks") => Ok(get_tasks(req, pool).await?),
        _ => Ok(Response::builder()
            .status(404)
            .body(Body::from("Not Found"))?)
    }
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    dotenv::dotenv().ok();
    
    let pool = db::initialize_db()
        .await
        .expect("Failed to initialize database");

    let provider = opentelemetry_sdk::trace::TracerProvider::builder()
        .with_simple_exporter(opentelemetry_stdout::SpanExporter::default())
        .with_resource(Resource::new(vec![
            opentelemetry::KeyValue::new("service.name", "lambda-http"),
        ]))
        .build();
    global::set_tracer_provider(provider);

    tracing_subscriber::registry()
        .with(fmt::layer().with_target(false))
        .with(tracing_opentelemetry::layer())
        .try_init()?;

    let result = run(service_fn(|req| function_handler(req, &pool))).await;
    
    global::shutdown_tracer_provider();
    
    result
}