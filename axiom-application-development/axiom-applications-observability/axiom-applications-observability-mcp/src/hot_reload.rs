use crate::error::Result;

pub struct HotReloadClient;

impl HotReloadClient {
    pub async fn new(_url: &str) -> Result<Self> {
        Ok(Self)
    }
}