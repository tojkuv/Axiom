use anyhow::Result;
use clap::Parser;
use std::path::PathBuf;
use tracing::{info, error};

mod mcp;
mod services;
mod clients;
mod config;

use crate::config::Settings;
use crate::mcp::server::AxiomAspireMcpServer;

#[derive(Parser)]
#[command(name = "axiom-aspire-mcp")]
#[command(about = "Axiom Aspire Deployer MCP Server")]
struct Args {
    #[arg(short, long, default_value = "config.toml")]
    config: PathBuf,
    
    #[arg(short, long, default_value = "3001")]
    port: u16,
    
    #[arg(short, long)]
    verbose: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    
    // Initialize tracing
    let subscriber = tracing_subscriber::FmtSubscriber::builder()
        .with_max_level(if args.verbose {
            tracing::Level::DEBUG
        } else {
            tracing::Level::INFO
        })
        .finish();
    
    tracing::subscriber::set_global_default(subscriber)?;
    
    info!("Starting Axiom Aspire MCP Server");
    
    // Load configuration
    let settings = Settings::from_file(&args.config)?;
    
    // Create and start MCP server
    let server = AxiomAspireMcpServer::new(settings).await?;
    
    info!("Axiom Aspire MCP Server listening on port {}", args.port);
    
    // Run server
    if let Err(e) = server.run(args.port).await {
        error!("Server error: {}", e);
        return Err(e);
    }
    
    info!("Axiom Aspire MCP Server stopped");
    Ok(())
}