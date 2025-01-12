use flutter_rust_bridge::frb;
pub use log::Level;

#[derive(Clone)]
pub struct LogEntry {
    pub time_millis: i64,
    pub msg: String,
    pub log_level: Level,
    pub lbl: String,
}

#[frb(mirror(Level))]
pub enum _Level {
    Error = 1,
    Warn,
    Info,
    Debug,
    Trace,
}
