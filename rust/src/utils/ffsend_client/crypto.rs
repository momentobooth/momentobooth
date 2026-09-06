//! Key derivation and metadata encryption for Firefox Send v3.
//!
//! Everything is derived from one random 16 byte secret, which is also the fragment of the download
//! URL. Whoever has the URL can decrypt the file; the server never sees the secret.

use aes_gcm::{aead::{Aead, KeyInit}, Aes128Gcm, Key, Nonce};
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine};
use serde::Serialize;

use super::ece::hkdf_no_salt;

/// Length of the Send secret in bytes.
const SECRET_LEN: usize = 16;

/// Length of the derived file and metadata keys in bytes.
const KEY_LEN: usize = 16;

/// Length of the derived authentication key in bytes.
const AUTH_KEY_LEN: usize = 64;

/// The keys derived from a single Send secret.
pub struct KeySet {
    secret: [u8; SECRET_LEN],
    meta_key: [u8; KEY_LEN],
    auth_key: [u8; AUTH_KEY_LEN],
}

impl KeySet {
    /// Generates a new random secret and derives every key from it.
    pub fn generate() -> Result<Self, CryptoError> {
        let mut secret = [0u8; SECRET_LEN];
        getrandom::fill(&mut secret).map_err(|_| CryptoError::Random)?;
        Ok(Self::from_secret(secret))
    }

    /// Derives the key set from an existing secret.
    pub fn from_secret(secret: [u8; SECRET_LEN]) -> Self {
        Self {
            secret,
            meta_key: hkdf_no_salt(&secret, b"metadata"),
            auth_key: hkdf_no_salt(&secret, b"authentication"),
        }
    }

    /// The raw secret. This is the input key material for the file encryption.
    pub fn secret(&self) -> &[u8] {
        &self.secret
    }

    /// The secret as it appears in the fragment of a download URL.
    pub fn secret_encoded(&self) -> String {
        URL_SAFE_NO_PAD.encode(self.secret)
    }

    /// The `authorization` value the server expects when the upload starts.
    pub fn authorization(&self) -> String {
        format!("send-v1 {}", URL_SAFE_NO_PAD.encode(self.auth_key))
    }

    /// Encrypts and encodes the file metadata.
    ///
    /// Send uses AES-128-GCM with an all-zero nonce here; the metadata key is used exactly once, so
    /// a fixed nonce is safe.
    pub fn encrypt_metadata(&self, metadata: &Metadata) -> Result<String, CryptoError> {
        let plaintext = serde_json::to_vec(metadata).map_err(|_| CryptoError::Serialize)?;

        let cipher = Aes128Gcm::new(Key::<Aes128Gcm>::from_slice(&self.meta_key));
        let ciphertext = cipher
            .encrypt(Nonce::from_slice(&[0u8; 12]), plaintext.as_slice())
            .map_err(|_| CryptoError::Encrypt)?;

        Ok(URL_SAFE_NO_PAD.encode(ciphertext))
    }
}

/// The metadata describing an uploaded file, encrypted before it reaches the server.
#[derive(Debug, Serialize)]
pub struct Metadata {
    pub name: String,
    #[serde(rename = "type")]
    pub mime: String,
    pub size: u64,
    pub manifest: Manifest,
}

impl Metadata {
    pub fn new(name: String, mime: String, size: u64) -> Self {
        Self {
            manifest: Manifest { files: vec![ManifestFile { name: name.clone(), mime: mime.clone(), size }] },
            name,
            mime,
            size,
        }
    }
}

/// The share manifest. MomentoBooth only ever shares a single file.
#[derive(Debug, Serialize)]
pub struct Manifest {
    pub files: Vec<ManifestFile>,
}

#[derive(Debug, Serialize)]
pub struct ManifestFile {
    pub name: String,
    #[serde(rename = "type")]
    pub mime: String,
    pub size: u64,
}

#[derive(Debug)]
pub enum CryptoError {
    Random,
    Serialize,
    Encrypt,
}

impl std::fmt::Display for CryptoError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CryptoError::Random => write!(f, "failed to generate a random secret"),
            CryptoError::Serialize => write!(f, "failed to serialize the file metadata"),
            CryptoError::Encrypt => write!(f, "failed to encrypt the file metadata"),
        }
    }
}

impl std::error::Error for CryptoError {}

#[cfg(test)]
mod tests {
    use super::*;

    const SECRET: [u8; SECRET_LEN] = *b"0123456789abcdef";

    /// Values produced by ffsend-api 0.7.3 for [`SECRET`], captured while it was still a
    /// dependency. They are what proves this implementation stayed wire-compatible after it was
    /// dropped: a mismatch means the server rejects the upload, or the download URL decrypts to
    /// nothing.
    const REFERENCE_META_KEY: &str = "1a6022e2a5cc8b00d790f1b858aa5e7f";
    const REFERENCE_AUTH_KEY: &str = "0ad4c7d841563234a52f37ba101be67e37b6685d1c69f09f4a2654de088d3c887d57a750d4f8a1789a5364f2ec77425fac160055fcc91587a52aecae3e89e958";
    const REFERENCE_AUTHORIZATION: &str = "send-v1 CtTH2EFWMjSlLze6EBvmfje2aF0cafCfSiZU3giNPIh9V6dQ1PiheJpTZPLsd0JfrBYAVfzJFYelKuyuPonpWA";
    const REFERENCE_METADATA_JSON: &str = r#"{"name":"photo.jpg","type":"image/jpeg","size":4242,"manifest":{"files":[{"name":"photo.jpg","type":"image/jpeg","size":4242}]}}"#;

    fn hex(bytes: &[u8]) -> String {
        bytes.iter().map(|b| format!("{b:02x}")).collect()
    }

    /// There is no file key to check: Send v3 feeds the raw secret into ECE as input key material,
    /// so ffsend-api's `derive_file_key` is a Send v2 concern only.
    #[test]
    fn derived_keys_match_ffsend_api() {
        let keys = KeySet::from_secret(SECRET);

        assert_eq!(hex(&keys.meta_key), REFERENCE_META_KEY);
        assert_eq!(hex(&keys.auth_key), REFERENCE_AUTH_KEY);
    }

    /// The metadata is encrypted deterministically with an all-zero nonce, so a matching key and a
    /// matching plaintext give a matching ciphertext.
    #[test]
    fn metadata_json_matches_ffsend_api() {
        let metadata = Metadata::new("photo.jpg".to_owned(), "image/jpeg".to_owned(), 4242);

        assert_eq!(serde_json::to_string(&metadata).expect("serialize metadata"), REFERENCE_METADATA_JSON);
    }

    #[test]
    fn encrypted_metadata_round_trips() {
        use aes_gcm::aead::Aead;

        let keys = KeySet::from_secret(SECRET);
        let encoded = keys.encrypt_metadata(&Metadata::new("photo.jpg".to_owned(), "image/jpeg".to_owned(), 4242)).expect("encrypt");

        let cipher = Aes128Gcm::new(Key::<Aes128Gcm>::from_slice(&keys.meta_key));
        let plaintext = cipher
            .decrypt(Nonce::from_slice(&[0u8; 12]), URL_SAFE_NO_PAD.decode(&encoded).expect("decode").as_slice())
            .expect("decrypt");

        assert_eq!(String::from_utf8(plaintext).expect("utf-8"), REFERENCE_METADATA_JSON);
    }

    #[test]
    fn authorization_is_the_encoded_auth_key() {
        assert_eq!(KeySet::from_secret(SECRET).authorization(), REFERENCE_AUTHORIZATION);
    }

    #[test]
    fn secret_is_encoded_url_safe_without_padding() {
        let encoded = KeySet::from_secret(SECRET).secret_encoded();

        assert!(!encoded.contains('='), "secret must not be padded: {encoded}");
        assert_eq!(URL_SAFE_NO_PAD.decode(&encoded).expect("decode"), SECRET);
    }

    #[test]
    fn generated_secrets_differ() {
        let a = KeySet::generate().expect("generate").secret_encoded();
        let b = KeySet::generate().expect("generate").secret_encoded();

        assert_ne!(a, b);
    }
}
