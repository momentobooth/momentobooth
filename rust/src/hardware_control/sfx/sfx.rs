use std::{io::Cursor, sync::LazyLock};
use dashmap::DashMap;
use parking_lot::RwLock;
use snafu::{prelude::*, ResultExt};
use kira::{
	backend::cpal::{self}, sound::{static_sound::StaticSoundData, FromFileError}, AudioManager, AudioManagerSettings, DefaultBackend, PlaySoundError
};

// //////////// //
// Global state //
// //////////// //

static AUDIO_MANAGER_LOCK: RwLock<Option<AudioManager>> = RwLock::new(None);
static CACHED_SOUNDS: LazyLock<DashMap<u8, StaticSoundData>> = LazyLock::new(|| DashMap::<u8, StaticSoundData>::new());

// /////// //
// Methods //
// /////// //

pub fn initialize() -> Result<(), SfxError> {
    let manager = AudioManager::<DefaultBackend>::new(AudioManagerSettings::default()).context(CPALInitFailedSnafu {})?;
    *AUDIO_MANAGER_LOCK.write() = Some(manager);
    Ok(())
}

pub fn load_audio(id: u8, raw_audio_data: Vec<u8>) -> Result<(), SfxError> {
    let data_cursor: Cursor<Vec<u8>> = Cursor::new(raw_audio_data);
    let sound_data = StaticSoundData::from_cursor(data_cursor).context(AudioFragmentLoadFailedSnafu {})?;
    CACHED_SOUNDS.insert(id, sound_data);
    Ok(())
}

pub fn clear_audio(id: u8) {
    CACHED_SOUNDS.remove(&id);
}

pub fn play_audio_if_loaded(id: u8) -> Result<(), SfxError> {
    let mut manager_guard = AUDIO_MANAGER_LOCK.write();
    if let Some(sound_data) = CACHED_SOUNDS.get(&id) {
        let manager = manager_guard.as_mut().context(NotInitializedSnafu)?;
        manager.play(sound_data.clone()).context(AudioPlaybackSnafu { fragment_id: id })?;
    }
    Ok(())
}

// ////// //
// Errors //
// ////// //

#[derive(Debug, Snafu)]
#[snafu(visibility(pub(crate)))]
pub enum SfxError {
    #[snafu(display("Could not initialize SFX subsystem due to a CPAL error"))]
    CPALInitFailed { source: cpal::Error },

    #[snafu(display("Tried to use SFX subsystem without initialization"))]
    NotInitialized,

    #[snafu(display("Could not load audio fragment to cache"))]
    AudioFragmentLoadFailed { source: FromFileError },

    #[snafu(display("Could not find audio fragment with id {}", fragment_id))]
    AudioFragmentNotFound { fragment_id: u8 },

    #[snafu(display("Could not play audio fragment with id {}", fragment_id))]
    AudioPlaybackError { fragment_id: u8, source: PlaySoundError<()> },
}
