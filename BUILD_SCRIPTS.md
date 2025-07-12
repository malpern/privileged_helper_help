# Build Scripts Overview

This repository contains several build scripts for different testing scenarios. Here's what each one does:

## Recommended Scripts

### `build_and_sign.sh` ⭐ **START HERE**
- **Purpose**: Main build script for testing SMAppService
- **Requirements**: Developer ID certificate
- **Output**: Properly signed app bundle
- **Use when**: You want to test SMAppService registration

### `build_developer_id.sh` 
- **Purpose**: Advanced build with full notarization pipeline
- **Requirements**: Developer ID certificate + app-specific password
- **Output**: Signed, notarized, and stapled app
- **Use when**: You want to test the complete distribution process

## Alternative Scripts (For Specific Testing)

### `build_test.sh`
- **Purpose**: Quick unsigned build for basic testing
- **Requirements**: None
- **Output**: Unsigned app bundle
- **Use when**: Testing basic functionality without SMAppService

### `build_adhoc.sh`
- **Purpose**: Ad-hoc signed build (local testing only)
- **Requirements**: None (uses ad-hoc signing)
- **Output**: Ad-hoc signed app
- **Use when**: You don't have Developer ID but want some signing

## Legacy/Experimental Scripts

The following scripts were created during development and testing:
- `build_and_sign_local.sh` - Early version with Apple Development cert
- `build_with_dev_cert.sh` - Another development certificate variant 
- `build_and_test.sh` - Basic build with test runner

**Recommendation**: Ignore these unless you're debugging specific signing scenarios.

## Quick Start

For most users, just run:
```bash
./build_and_sign.sh
```

Then follow the instructions to update your Developer ID certificate.