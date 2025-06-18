use crate::error::Result;

pub struct SimulatorController;

impl SimulatorController {
    pub async fn new() -> Result<Self> {
        Ok(Self)
    }
}