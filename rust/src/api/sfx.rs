use crate::hardware_control::sfx::*;

pub fn initialize() -> Result<(), sfx::SfxError> {
    sfx::initialize()
}

pub fn load_audio(id: u8, raw_audio_data: Vec<u8>) -> Result<(), sfx::SfxError> {
    sfx::load_audio(id, raw_audio_data)
}

pub fn clear_audio(id: u8) {
    sfx::clear_audio(id)
}

pub fn play_audio_if_loaded(id: u8) -> Result<(), sfx::SfxError> {
    sfx::play_audio_if_loaded(id)
}
