#!/bin/bash
set -e

echo "=== Automated Privileged Helper Testing ==="
echo "Timestamp: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
PROJECT_DIR="$(pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_BUNDLE="${BUILD_DIR}/HelperPOCApp.app"
LOG_DIR="${PROJECT_DIR}/logs"
APP_LOG="/tmp/helperpoc-app.log"
DAEMON_LOG="/tmp/helperpoc-daemon.log"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

wait_for_condition() {
    local condition_cmd="$1"
    local timeout="$2"
    local description="$3"
    
    log_info "Waiting for: $description (timeout: ${timeout}s)"
    
    local count=0
    while [ $count -lt $timeout ]; do
        if eval "$condition_cmd" &>/dev/null; then
            log_success "$description"
            return 0
        fi
        sleep 1
        count=$((count + 1))
        echo -n "."
    done
    echo ""
    log_error "Timeout waiting for: $description"
    return 1
}

check_log_files() {
    log_info "Checking log files..."
    
    # Create logs directory
    mkdir -p "$LOG_DIR"
    
    # Clear previous logs
    > "$APP_LOG" 2>/dev/null || true
    > "$DAEMON_LOG" 2>/dev/null || true
    
    log_success "Log files initialized"
    echo "  App log: $APP_LOG"
    echo "  Daemon log: $DAEMON_LOG"
}

build_project() {
    log_info "Building project..."
    
    if ./build_and_test.sh &>/dev/null; then
        log_success "Build completed"
    else
        log_error "Build failed"
        return 1
    fi
    
    if [ ! -d "$APP_BUNDLE" ]; then
        log_error "App bundle not found at $APP_BUNDLE"
        return 1
    fi
    
    log_success "App bundle ready"
}

launch_app() {
    log_info "Launching app..."
    
    # Kill any existing instances
    pkill -f "HelperPOCApp" || true
    sleep 1
    
    # Launch the app in background
    open "$APP_BUNDLE"
    
    # Wait for app to start
    if wait_for_condition "pgrep -f 'HelperPOCApp'" 10 "App to start"; then
        log_success "App launched successfully"
        return 0
    else
        log_error "Failed to launch app"
        return 1
    fi
}

check_helper_status() {
    log_info "Checking helper status..."
    
    # Use launchctl to check if helper is loaded
    if launchctl list | grep -q "com.keypath.helperpoc"; then
        log_success "Helper is loaded in launchd"
        launchctl list | grep "com.keypath.helperpoc"
        return 0
    else
        log_warning "Helper not found in launchd"
        return 1
    fi
}

simulate_helper_registration() {
    log_info "Simulating helper registration..."
    
    # For now, we can't fully automate the user approval process
    # But we can check if the registration attempt was made
    
    log_warning "Helper registration requires manual user approval"
    log_info "You would need to:"
    echo "  1. Click 'Register Helper' in the app"
    echo "  2. Approve in System Settings > General > Login Items"
    echo "  3. Click 'Test Helper' to verify"
    
    return 0
}

monitor_logs() {
    local duration="$1"
    log_info "Monitoring logs for ${duration} seconds..."
    
    # Start log monitoring in background
    (
        echo "=== App Log Monitoring ==="
        tail -f "$APP_LOG" 2>/dev/null &
        APP_TAIL_PID=$!
        
        echo "=== Daemon Log Monitoring ==="
        tail -f "$DAEMON_LOG" 2>/dev/null &
        DAEMON_TAIL_PID=$!
        
        # Wait for specified duration
        sleep "$duration"
        
        # Kill tail processes
        kill $APP_TAIL_PID $DAEMON_TAIL_PID 2>/dev/null || true
    )
}

analyze_logs() {
    log_info "Analyzing logs..."
    
    echo ""
    echo "=== APP LOG ANALYSIS ==="
    if [ -f "$APP_LOG" ] && [ -s "$APP_LOG" ]; then
        log_success "App log file exists and has content"
        echo "Recent entries:"
        tail -5 "$APP_LOG" | sed 's/^/  /'
        
        # Check for key events
        if grep -q "Helper status" "$APP_LOG"; then
            log_success "Status checking logged"
        fi
        
        if grep -q "registration" "$APP_LOG"; then
            log_success "Registration attempts logged"
        fi
    else
        log_warning "App log file is empty or missing"
    fi
    
    echo ""
    echo "=== DAEMON LOG ANALYSIS ==="
    if [ -f "$DAEMON_LOG" ] && [ -s "$DAEMON_LOG" ]; then
        log_success "Daemon log file exists and has content"
        echo "Recent entries:"
        tail -5 "$DAEMON_LOG" | sed 's/^/  /'
        
        # Check for key events
        if grep -q "Helper daemon starting" "$DAEMON_LOG"; then
            log_success "Daemon startup logged"
        fi
        
        if grep -q "XPC connection" "$DAEMON_LOG"; then
            log_success "XPC communication logged"
        fi
    else
        log_warning "Daemon log file is empty or missing"
    fi
}

cleanup() {
    log_info "Cleaning up..."
    
    # Kill app
    pkill -f "HelperPOCApp" || true
    
    # Unload helper if it exists
    launchctl unload "/tmp/com.keypath.helperpoc.plist" 2>/dev/null || true
    
    log_success "Cleanup completed"
}

run_full_test() {
    log_info "Starting full automated test suite..."
    echo ""
    
    # Initialize
    check_log_files || return 1
    echo ""
    
    # Build
    build_project || return 1
    echo ""
    
    # Launch
    launch_app || return 1
    echo ""
    
    # Monitor for a short time
    monitor_logs 5
    echo ""
    
    # Check status
    check_helper_status
    echo ""
    
    # Simulate registration process
    simulate_helper_registration
    echo ""
    
    # Give time for user interaction if needed
    log_info "Waiting 30 seconds for potential user interaction..."
    sleep 30
    echo ""
    
    # Final log analysis
    analyze_logs
    echo ""
    
    # Cleanup
    cleanup
    echo ""
    
    log_success "Automated test completed!"
    echo ""
    echo "=== NEXT STEPS ==="
    echo "1. Review log files:"
    echo "   - App log: $APP_LOG"
    echo "   - Daemon log: $DAEMON_LOG"
    echo "2. For full testing, manually:"
    echo "   - Launch app: open $APP_BUNDLE"
    echo "   - Click 'Register Helper'"
    echo "   - Approve in System Settings"
    echo "   - Click 'Test Helper'"
}

# Main execution
case "${1:-full}" in
    "build")
        build_project
        ;;
    "launch")
        launch_app
        ;;
    "logs")
        analyze_logs
        ;;
    "cleanup")
        cleanup
        ;;
    "monitor")
        monitor_logs "${2:-10}"
        ;;
    "full")
        run_full_test
        ;;
    *)
        echo "Usage: $0 [build|launch|logs|cleanup|monitor <seconds>|full]"
        echo "Default: full"
        ;;
esac