//! Encrypted Content-Encoding (RFC 8188, `aes128gcm`) as used by Firefox Send v3.
//!
//! The ciphertext is a 21 byte header followed by fixed size records. Every record is padded to
//! exactly [`RECORD_SIZE`] bytes including its GCM tag, which means the plaintext of a record is
//! [`Self::plaintext_record_size`] bytes. The last record carries a different padding delimiter,
//! so the total plaintext length has to be known up front.

use aes_gcm::{aead::{Aead, KeyInit}, Aes128Gcm, Key, Nonce};
use hkdf::Hkdf;
use sha2::Sha256;

/// The record size Firefox Send v3 uses. Also written into the header.
pub const RECORD_SIZE: u32 = 1024 * 64;

/// Length of the ECE header: salt (16) + record size (4) + key id length (1).
pub const HEADER_LEN: usize = 21;

/// Length of the AES-GCM authentication tag.
const TAG_LEN: usize = 16;

/// Length of the crypto salt in bytes.
pub const SALT_LEN: usize = 16;

/// Length of the derived content encryption key in bytes.
const KEY_LEN: usize = 16;

/// Length of the derived base nonce in bytes.
const NONCE_LEN: usize = 12;

/// HKDF info for the content encryption key. The trailing NUL is part of the RFC.
const KEY_INFO: &[u8] = b"Content-Encoding: aes128gcm\0";

/// HKDF info for the base nonce. The trailing NUL is part of the RFC.
const NONCE_INFO: &[u8] = b"Content-Encoding: nonce\0";

/// Encrypts a plaintext of known length into ECE records.
pub struct EceEncrypter {
    cipher: Aes128Gcm,
    base_nonce: [u8; NONCE_LEN],
    salt: [u8; SALT_LEN],

    /// Sequence number of the next record, used to derive its nonce.
    seq: u32,

    /// Number of plaintext bytes handed to [`Self::encrypt_record`] so far.
    consumed: u64,

    /// Total number of plaintext bytes that will be encrypted.
    total: u64,
}

impl EceEncrypter {
    /// Creates an encrypter for a plaintext of `total` bytes, keyed on the raw Send secret.
    pub fn new(secret: &[u8], total: u64, salt: [u8; SALT_LEN]) -> Self {
        let key: [u8; KEY_LEN] = hkdf(&salt, secret, KEY_INFO);
        let base_nonce: [u8; NONCE_LEN] = hkdf(&salt, secret, NONCE_INFO);

        Self {
            cipher: Aes128Gcm::new(Key::<Aes128Gcm>::from_slice(&key)),
            base_nonce,
            salt,
            seq: 0,
            consumed: 0,
            total,
        }
    }

    /// The number of plaintext bytes that fit in one record.
    ///
    /// Every record holds the padding delimiter and the GCM tag on top of the plaintext.
    pub const fn plaintext_record_size() -> usize {
        RECORD_SIZE as usize - TAG_LEN - 1
    }

    /// The 21 byte ECE header, which has to be sent before the first record.
    pub fn header(&self) -> Vec<u8> {
        let mut header = Vec::with_capacity(HEADER_LEN);
        header.extend_from_slice(&self.salt);
        header.extend_from_slice(&RECORD_SIZE.to_be_bytes());
        header.push(0); // Key id length; Send does not use a key id.
        header
    }

    /// Total size of the ciphertext, header included.
    ///
    /// Every record but the last is padded to [`RECORD_SIZE`]; the last one carries only its
    /// plaintext, the `0x02` delimiter and the tag. An empty plaintext still produces one record.
    ///
    /// Nothing in the upload path needs this, but checking it against the reference ciphertext
    /// lengths is what proves the record maths is right.
    #[cfg(test)]
    pub fn ciphertext_len(&self) -> u64 {
        let plaintext_record_size = Self::plaintext_record_size() as u64;
        let full_records = self.total.saturating_sub(1) / plaintext_record_size;
        let last_record_plaintext = self.total - full_records * plaintext_record_size;

        HEADER_LEN as u64 + full_records * RECORD_SIZE as u64 + last_record_plaintext + 1 + TAG_LEN as u64
    }

    /// Encrypts one record of plaintext.
    ///
    /// `plaintext` must be at most [`Self::plaintext_record_size`] bytes, and every record before
    /// the last one must be exactly that size.
    ///
    /// # Panics
    ///
    /// Panics if more plaintext is fed in than the `total` this encrypter was created with.
    pub fn encrypt_record(&mut self, plaintext: &[u8]) -> Result<Vec<u8>, EceError> {
        assert!(plaintext.len() <= Self::plaintext_record_size(), "ECE record plaintext too large");

        self.consumed += plaintext.len() as u64;
        assert!(self.consumed <= self.total, "more plaintext encrypted than announced");
        let is_last = self.consumed >= self.total;

        // Pad to a full record: 0x02 marks the final record, 0x01 followed by zeroes any other.
        let mut padded = Vec::with_capacity(RECORD_SIZE as usize - TAG_LEN);
        padded.extend_from_slice(plaintext);
        if is_last {
            padded.push(2);
        } else {
            padded.resize(RECORD_SIZE as usize - TAG_LEN, 0);
            padded[plaintext.len()] = 1;
        }

        let nonce = self.record_nonce();
        self.seq = self.seq.checked_add(1).expect("ECE record sequence overflow");

        self.cipher
            .encrypt(Nonce::from_slice(&nonce), padded.as_slice())
            .map_err(|_| EceError::Encrypt)
    }

    /// Whether every announced plaintext byte has been encrypted.
    pub fn is_done(&self) -> bool {
        self.consumed >= self.total
    }

    /// Derives the nonce for the current record by XOR-ing the sequence number into the base nonce.
    fn record_nonce(&self) -> [u8; NONCE_LEN] {
        let mut nonce = self.base_nonce;
        let tail = u32::from_be_bytes(nonce[NONCE_LEN - 4..].try_into().expect("nonce tail is 4 bytes"));
        nonce[NONCE_LEN - 4..].copy_from_slice(&(tail ^ self.seq).to_be_bytes());
        nonce
    }
}

/// Derives `N` bytes from `ikm` with HKDF-SHA256.
pub fn hkdf<const N: usize>(salt: &[u8], ikm: &[u8], info: &[u8]) -> [u8; N] {
    let mut okm = [0u8; N];
    Hkdf::<Sha256>::new(Some(salt), ikm)
        .expand(info, &mut okm)
        .expect("HKDF output length is valid for SHA-256");
    okm
}

/// Derives `N` bytes from `ikm` with HKDF-SHA256 without a salt.
pub fn hkdf_no_salt<const N: usize>(ikm: &[u8], info: &[u8]) -> [u8; N] {
    let mut okm = [0u8; N];
    Hkdf::<Sha256>::new(None, ikm)
        .expand(info, &mut okm)
        .expect("HKDF output length is valid for SHA-256");
    okm
}

#[derive(Debug)]
pub enum EceError {
    Encrypt,
}

impl std::fmt::Display for EceError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            EceError::Encrypt => write!(f, "failed to encrypt an ECE record"),
        }
    }
}

impl std::error::Error for EceError {}

#[cfg(test)]
mod tests {
    use super::*;
    use sha2::{Digest, Sha256};

    /// Reference ciphertexts produced by ffsend-api 0.7.3 for a plaintext of `n` bytes where
    /// `plaintext[i] == (i % 251) as u8`, with the secret and salt below.
    ///
    /// These were captured while ffsend-api was still a dependency and are what proves this
    /// implementation stayed wire-compatible after it was dropped. The sizes cover both sides of
    /// every record and padding boundary. Regenerate them against ffsend-api if they ever need to
    /// change: a mismatch means uploads will be silently corrupt, not merely different.
    const REFERENCE_VECTORS: &[(usize, usize, &str)] = &[
        (1, 39, "839c937dff25aaca67435aa6111390e1897dcce24d72aab751ac5be87c695172"),
        (15, 53, "e18bce0fef354c86ee353d2ab68c38cb3a2bc0301a0c4f94e7908f08746cf796"),
        (16, 54, "f093a96168828822c6e601237c52519294950233f04768a1116a27fef18f0987"),
        (17, 55, "ef09e571d957bc2576abfad5bd90ca423b03e537be0c9298f30a5b57856e17d9"),
        (1024, 1062, "a0c0c59b45ef2fd497160f40423bce7934dcd86a5fa389d24acbf7357a69abca"),
        (65518, 65556, "8a24d1c8a3e73f8d638c79b757db876583d2147e613ca50ebbfea669ea24605e"),
        (65519, 65557, "f669cc326859732bd8f83c2a23ab9ec685ff592d347672a0223510206a8aa3c5"),
        (65520, 65575, "23e53ca66cbca1d63d8f1cda4ab8195edc27c465bd171d2d350532535eb917f4"),
        (131037, 131092, "c918c212f82e3fee29e2a277b4e683122b2c5deccbe5b42c162a268336ff6351"),
        (131038, 131093, "d3c75725f8fbd6a85f2223fd6b16952cb26caef2955c2f6493e11bfe863c39ab"),
        (131039, 131111, "d1719d86474c6cc7a7655509d5a26468bfc71f752b3c1733c63908231d571a4a"),
        (200000, 200089, "bdd3ad74ded092f0be6e8d86a45391221b78e4b6e6a01ab10664b5de04d49ebb"),
    ];

    const SECRET: &[u8] = b"0123456789abcdef";
    const SALT: [u8; SALT_LEN] = *b"fedcba9876543210";

    /// Encrypts `plaintext` in full, returning the header and every record concatenated.
    fn encrypt_all(secret: &[u8], salt: [u8; SALT_LEN], plaintext: &[u8]) -> Vec<u8> {
        let mut encrypter = EceEncrypter::new(secret, plaintext.len() as u64, salt);
        let mut out = encrypter.header();

        let mut offset = 0;
        loop {
            let end = (offset + EceEncrypter::plaintext_record_size()).min(plaintext.len());
            out.extend_from_slice(&encrypter.encrypt_record(&plaintext[offset..end]).expect("encrypt"));
            offset = end;
            if encrypter.is_done() {
                break;
            }
        }

        assert_eq!(out.len() as u64, encrypter.ciphertext_len(), "ciphertext_len disagrees with output");
        out
    }

    fn hex(bytes: &[u8]) -> String {
        bytes.iter().map(|b| format!("{b:02x}")).collect()
    }

    #[test]
    fn matches_ffsend_api_byte_for_byte() {
        for &(size, expected_len, expected_digest) in REFERENCE_VECTORS {
            let plaintext: Vec<u8> = (0..size).map(|i| (i % 251) as u8).collect();
            let ciphertext = encrypt_all(SECRET, SALT, &plaintext);

            assert_eq!(ciphertext.len(), expected_len, "ciphertext length differs for {size} plaintext bytes");
            assert_eq!(hex(&Sha256::digest(&ciphertext)), expected_digest, "ciphertext differs for {size} plaintext bytes");
        }
    }

    /// RFC 8188 has no representation for zero records, so an empty plaintext produces a record
    /// holding nothing but the final delimiter. ffsend-api returned an empty ciphertext instead,
    /// which is why this case is not in [`REFERENCE_VECTORS`].
    #[test]
    fn empty_plaintext_still_produces_one_record() {
        assert_eq!(encrypt_all(SECRET, SALT, &[]).len(), HEADER_LEN + 1 + TAG_LEN);
    }

    #[test]
    fn header_is_salt_record_size_and_key_id_length() {
        let header = EceEncrypter::new(SECRET, 0, SALT).header();

        assert_eq!(header.len(), HEADER_LEN);
        assert_eq!(&header[..SALT_LEN], &SALT);
        assert_eq!(&header[SALT_LEN..SALT_LEN + 4], &RECORD_SIZE.to_be_bytes());
        assert_eq!(header[HEADER_LEN - 1], 0);
    }

    #[test]
    fn only_the_last_record_is_short() {
        const TOTAL: usize = 200_000;
        let mut encrypter = EceEncrypter::new(SECRET, TOTAL as u64, SALT);
        let chunk = vec![7u8; EceEncrypter::plaintext_record_size()];

        let mut remaining = TOTAL;
        while remaining > 0 {
            let take = remaining.min(chunk.len());
            let record = encrypter.encrypt_record(&chunk[..take]).expect("encrypt");
            remaining -= take;

            if remaining > 0 {
                assert_eq!(record.len(), RECORD_SIZE as usize, "intermediate record is not padded");
            } else {
                assert_eq!(record.len(), take + 1 + TAG_LEN, "last record has unexpected size");
            }
        }
        assert!(encrypter.is_done());
    }
}
