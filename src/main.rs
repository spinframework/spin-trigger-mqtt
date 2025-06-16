use clap::Parser;
use spin_runtime_factors::FactorsBuilder;
use spin_trigger::cli::FactorsTriggerCommand;
use trigger_mqtt::MqttTrigger;

type Command = FactorsTriggerCommand<MqttTrigger, FactorsBuilder>;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    spin_telemetry::init(build_info())?;
    let trigger = Command::parse();
    trigger.run().await
}

/// Returns build information of the parent Spin process, similar to: 0.1.0 (2be4034 2022-03-31).
fn build_info() -> String {
    let spin_version = env_var("SPIN_VERSION");
    let spin_commit_sha = env_var("SPIN_COMMIT_SHA");
    let spin_commit_date = env_var("SPIN_COMMIT_DATE");
    format!("{spin_version} ({spin_commit_sha} {spin_commit_date})")
}

fn env_var(name: &str) -> String {
    std::env::var(name).unwrap_or_else(|_| "unknown".to_string())
}
