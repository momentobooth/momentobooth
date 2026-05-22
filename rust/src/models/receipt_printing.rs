pub struct Receipt {
    pub commands: Vec<ReceiptPrinterCommand>,
}

pub enum ReceiptPrinterCommand {
    PrintImage(Vec<u8>),
    PrintText(String),
    Feed,
    Cut,
}
