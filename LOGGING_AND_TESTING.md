# Logging and Testing Documentation

## Overview

The PrivilegedHelper POC now includes comprehensive logging and automated testing capabilities for debugging and development.

## Log Files

### Application Log
- **Location**: `/tmp/helperpoc-app.log`
- **Content**: Main app events, SMAppService operations, XPC communication
- **Access**: Direct file access for Claude Code debugging

### Daemon Log  
- **Location**: `/tmp/helperpoc-daemon.log`
- **Content**: Helper daemon events, XPC listener, privileged operations
- **Access**: Direct file access (created with appropriate permissions)

### Log Format
```
[TIMESTAMP] [LEVEL] [SOURCE] MESSAGE
```

Example:
```
[2025-07-09T01:25:37Z] [INFO] [APP] === HelperPOC App Started ===
[2025-07-09T01:25:37Z] [INFO] [APP] Helper status: SMAppServiceStatus(rawValue: 3)
```

## Testing Scripts

### 1. Automated Test Suite
**File**: `automated_test.sh`

**Usage**:
```bash
./automated_test.sh [command]
```

**Commands**:
- `full` (default) - Complete test workflow
- `build` - Build project only
- `launch` - Launch app only  
- `logs` - Analyze log files
- `cleanup` - Clean up processes
- `monitor <seconds>` - Monitor logs for specified duration

**Features**:
- ✅ Automated build verification
- ✅ App launch detection
- ✅ Helper status checking
- ✅ Log file monitoring
- ✅ Color-coded output
- ✅ Process cleanup

### 2. Real-time Log Monitor
**File**: `log_monitor.sh`

**Usage**:
```bash
./log_monitor.sh
```

**Features**:
- Real-time monitoring of both app and daemon logs
- Color-coded prefixes ([APP] vs [DAEMON])
- Ctrl+C to stop monitoring

## Testing Workflow

### Automated Testing
```bash
# Run full automated test
./automated_test.sh

# Monitor logs in real-time (separate terminal)
./log_monitor.sh

# Manual app testing
open build/HelperPOCApp.app
```

### Manual Testing Steps
1. **Build & Launch**:
   ```bash
   ./build_and_test.sh
   open build/HelperPOCApp.app
   ```

2. **Monitor Logs**:
   ```bash
   # Terminal 1: Real-time monitoring
   ./log_monitor.sh
   
   # Terminal 2: Direct log access
   tail -f /tmp/helperpoc-app.log
   tail -f /tmp/helperpoc-daemon.log
   ```

3. **Test Helper Registration**:
   - Click "Register Helper" in app
   - Check logs for registration events
   - Verify helper status in launchctl

4. **Test XPC Communication**:
   - Click "Test Helper" in app
   - Monitor daemon log for XPC connections
   - Verify privileged operations

## Log Analysis

### Key Log Events to Monitor

#### App Events
- App startup: `=== HelperPOC App Started ===`
- Status checks: `Helper status: SMAppServiceStatus`
- Registration: `Attempting to register helper`
- XPC calls: `Starting helper test`

#### Daemon Events  
- Daemon startup: `=== HelperPOC Daemon Started ===`
- XPC connections: `Received new XPC connection request`
- Client validation: `Client validation passed`
- Operations: `Creating test file`

### Status Codes
- `SMAppServiceStatus(rawValue: 0)` - Not registered
- `SMAppServiceStatus(rawValue: 1)` - Enabled
- `SMAppServiceStatus(rawValue: 2)` - Requires approval
- `SMAppServiceStatus(rawValue: 3)` - Not found

## Debugging with Claude Code

### Direct Log Access
Claude Code can directly read log files for debugging:

```bash
# Check app events
cat /tmp/helperpoc-app.log

# Check daemon events  
cat /tmp/helperpoc-daemon.log

# Monitor in real-time
tail -f /tmp/helperpoc-app.log
```

### Common Issues & Solutions

#### 1. Empty Log Files
**Symptoms**: Log files exist but are empty
**Solution**: Check app bundle path in FileLogger, ensure /tmp permissions

#### 2. Daemon Not Starting
**Symptoms**: Only app logs, no daemon logs
**Solution**: Check SMAppService registration, launchctl status

#### 3. XPC Connection Failures
**Symptoms**: App logs show XPC errors
**Solution**: Check helper status, client validation logs

## Integration with KeypathRecorder

### Logging Strategy
1. **Development**: Use `/tmp/` logs for easy access
2. **Production**: Consider system logs or user Documents folder
3. **Debug Mode**: Enable verbose logging via environment variable

### Testing Integration
1. **Build Phase**: Automated build verification
2. **Registration Phase**: Helper setup validation  
3. **Operation Phase**: Kanata launch testing
4. **Cleanup Phase**: Proper resource cleanup

## Example Test Session

```bash
# Terminal 1: Start monitoring
./log_monitor.sh

# Terminal 2: Run automated test
./automated_test.sh

# Expected output in monitor:
[APP] === HelperPOC App Started ===
[APP] Helper status: SMAppServiceStatus(rawValue: 3)
[DAEMON] === HelperPOC Daemon Started ===
[DAEMON] Helper daemon listening for XPC connections
```

This comprehensive logging and testing setup provides full visibility into the privileged helper workflow and enables effective debugging during development.