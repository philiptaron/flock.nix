# Secrets Management

This document describes the planned approach for managing encrypted secrets in this repository.

## Overview

Secrets will be encrypted using [age](https://github.com/FiloSottile/age) with multiple recipients, allowing any authorized device to decrypt. On macOS, keys will be backed by the Secure Enclave and protected with Touch ID. On Linux, standard age keys will be stored on disk.

## Device Setup

### macOS (Secure Enclave)

Each Mac will have a hardware-backed key that never leaves the Secure Enclave. This requires macOS Sequoia or later.

Create the key:
```bash
sc_auth create-ctk-identity -l ssh -k p-256-ne -t bio
```

Export the public key:
```bash
ssh-keygen -w /usr/lib/ssh-keychain.dylib -K -N ""
# Creates id_ecdsa_sk_rk.pub
```

Add to shell profile for seamless SSH/age integration:
```bash
export SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib
```

### Linux

TODO: Document Linux key setup when we get there.

## Recipients

All public keys are collected in a recipients file. A secret encrypted to these keys can be decrypted by any single one of them.

```
# recipients.txt

# Mac 1 - Secure Enclave (Touch ID required)
ecdsa-sha2-nistp256 AAAA... mac1

# Mac 2 - Secure Enclave (Touch ID required)
ecdsa-sha2-nistp256 AAAA... mac2
```

## Encrypting Secrets

### Raw files with age

```bash
age -R recipients.txt -o secret.age secret.txt
```

### Structured files with sops

For YAML/JSON configuration files, sops encrypts individual values while keeping keys visible:

```bash
sops --encrypt --age "age1...,age1..." secrets.yaml > secrets.enc.yaml
```

Or configure `.sops.yaml` for automatic key selection:

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: >-
      age1abc...,
      age1def...
```

Then simply:
```bash
sops secrets/api-keys.yaml
```

## Decrypting Secrets

### On macOS (Touch ID prompt)

```bash
age -d -i ~/.ssh/id_ecdsa_sk_rk secret.age
```

### With sops

sops automatically finds keys in standard locations:
```bash
sops secrets/api-keys.yaml  # Opens decrypted in $EDITOR
sops -d secrets/api-keys.yaml  # Prints decrypted to stdout
```

## Managing Devices

### Adding a new device

1. Generate a key on the new device
2. Add the public key to `recipients.txt`
3. Re-encrypt all secrets to include the new recipient:
   ```bash
   sops updatekeys secrets/file.yaml
   ```

### Removing a device

1. Remove the public key from `recipients.txt`
2. Re-encrypt all secrets:
   ```bash
   sops updatekeys secrets/file.yaml
   ```
3. Rotate any secrets the device had access to (it may have decrypted them previously)

## Limitations

### iOS

There is no practical way to run age or sops on iOS. Secrets that need to be accessible on iPhone should be stored separately in iCloud Keychain or a password manager.

### Key loss

Secure Enclave keys are non-exportable by design. If a Mac is lost or wiped, that key is gone. This is acceptable because secrets are encrypted to multiple recipients—other devices can still decrypt. Just remove the lost device's public key and re-encrypt.

## Integration with Nix

The plan is to use [sops-nix](https://github.com/Mic92/sops-nix) for integration with NixOS. This will:

1. Store encrypted secrets in this repository
2. Decrypt them at activation time to `/run/secrets/`
3. Reference the decrypted paths in Nix configurations

This keeps secrets encrypted at rest in git while making them available to services and configurations at runtime.
