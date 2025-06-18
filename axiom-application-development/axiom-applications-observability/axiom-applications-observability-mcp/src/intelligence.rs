use crate::error::Result;

pub struct IntelligenceClient;

impl IntelligenceClient {
    pub async fn new(_url: &str) -> Result<Self> {
        Ok(Self)
    }
}