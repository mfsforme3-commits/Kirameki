# Kirameki Authentication & Sync Specification

## Goals
- Allow users to authenticate and use the app entirely offline
- Support device-to-device login transfer without central server availability
- Sync credentials and playback data with Supabase twice daily when online
- Preserve security and privacy: all secrets encrypted at rest, minimal exposure over network

## Terminology
- **Master Key (MK)**: Random 256-bit key generated per user; used to encrypt user vault
- **Device Key (DK)**: Random 256-bit key generated per device; encrypted with MK for storage
- **Password Derived Key (PDK)**: Key derived from user password via Argon2id
- **Vault**: Encrypted JSON containing user profile, device list, playback tokens
- **Sync Snapshot**: Encrypted blob uploaded to Supabase during sync windows

## Cryptography
- Password hashing: Argon2id (time cost 3, memory cost 64MB, parallelism 2)
- Symmetric encryption: AES-256-GCM with random 96-bit nonce
- Randomness: `cryptography` package backed by platform secure RNG
- Key storage: `flutter_secure_storage` (Keychain/KeyStore) for MK; fallback to encrypted file on desktop

## Account Creation (Offline)
1. User enters email (optional) + password on device
2. Generate MK, DK, and Device ID (UUIDv4)
3. Derive PDK from password using Argon2id
4. Encrypt MK with PDK → `EncMK`
5. Encrypt device credentials (DK, device metadata) with MK
6. Persist:
   - Secure storage: `EncMK`
   - Local database: encrypted vault containing device record and empty playback lists
   - Create local session token (signed JWT using DK as HMAC secret)
7. Log user in locally

## Login (Offline)
1. Prompt password/biometric
2. Derive PDK from password
3. Decrypt `EncMK` → MK
4. Load vault, decrypt with MK
5. Validate device record; generate session token signed with DK
6. Launch user session

## Multi-Device QR Pairing (Offline)
1. Logged-in device (Host) exposes ephemeral WebSocket (TLS where available) or Bluetooth LE advertisement containing pairing code ID
2. Host displays QR containing:
   - Pairing server URL (local IP + port or BLE ID)
   - Ephemeral token (random 192-bit)
   - Host device signature (HMAC with DK)
3. Joining device scans QR, connects to host, sends greeting with new Device ID + public curve25519 key
4. Host validates token + signature, performs X3DH-style key agreement to derive shared secret
5. Host encrypts MK with shared secret, sends to joining device
6. Joining device decrypts MK, stores `EncMK` locally using its own PDK (prompt user for password)
7. Both devices update vault device list and sync playback data peer-to-peer (signed messages)

## Supabase Sync Windows (Online)
- Schedule: twice per day (configurable) when Supabase reachable
- Workflow:
  1. Attempt TLS connection to Supabase REST endpoint
  2. Authenticate using device session token signed by DK (shared secret stored on server from initial registration; fallback to email/password login when first window available)
  3. Upload encrypted sync snapshot (vault + playback state) — AES-GCM using MK
  4. Download latest snapshot timestamps
  5. If remote newer, fetch snapshot, decrypt with MK, merge using CRDT-like strategy (latest timestamp per field; union lists)
  6. Resolve conflicts; prompt user if destructive (e.g., password change)

## Data Model
```json
{
  "vaultVersion": 1,
  "user": {
    "id": "uuid",
    "email": "optional",
    "displayName": "string",
    "createdAt": "timestamp"
  },
  "devices": [
    {
      "deviceId": "uuid",
      "name": "Kirameki on Pixel 8",
      "platform": "android|ios|tv|windows|macos",
      "addedAt": "timestamp",
      "dk": "base64", // encrypted with MK
      "lastSeen": "timestamp"
    }
  ],
  "playback": {
    "continueWatching": [
      {"animeId": "string", "episodeId": "string", "position": 1234, "updatedAt": "timestamp"}
    ],
    "downloads": [
      {"episodeId": "string", "expiresAt": "timestamp", "path": "string"}
    ]
  }
}
```

## Security Considerations
- MK never stored unencrypted; kept in memory only during session
- Session tokens signed with DK; rotating DK invalidates old sessions
- QR payload expires in 90 seconds; host can revoke
- Biometric unlock optional; wraps password via platform APIs
- On logout, session token wiped; optionally purge downloads if user requests

## Error Handling
- Wrong password → incremental backoff, local lockout after 5 attempts (cooldown)
- Vault corruption → prompt for recovery; allow restore from Supabase snapshot when online
- Sync conflicts → maintain audit trail; user can choose dataset to keep

## Future Enhancements
- Social login when Supabase online (optional)
- Time-based one-time password (TOTP) for added security online
- Device approval notifications across paired devices
