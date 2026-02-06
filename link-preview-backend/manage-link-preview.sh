#!/bin/bash

# Link Preview Backend - Management Script
# Manage the link preview service easily

SERVICE_NAME="link-preview-backend"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo "======================================================"
    echo -e "${BLUE}$1${NC}"
    echo "======================================================"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if PM2 is installed
check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        print_error "PM2 is not installed"
        echo "Would you like to install PM2? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            npm install -g pm2
            if [ $? -eq 0 ]; then
                print_success "PM2 installed successfully"
            else
                print_error "Failed to install PM2"
                exit 1
            fi
        else
            exit 1
        fi
    fi
}

# Start the service
start_service() {
    print_header "Starting Link Preview Backend"
    
    check_pm2
    
    # Create logs directory
    mkdir -p logs
    
    # Check if already running
    if pm2 describe $SERVICE_NAME &>/dev/null; then
        print_warning "Service is already running"
        print_info "Use 'restart' to restart the service"
        pm2 status $SERVICE_NAME
        return
    fi
    
    # Start the service
    pm2 start ecosystem.config.js
    
    if [ $? -eq 0 ]; then
        pm2 save
        print_success "Service started successfully"
        pm2 status $SERVICE_NAME
    else
        print_error "Failed to start service"
        exit 1
    fi
}

# Stop the service
stop_service() {
    print_header "Stopping Link Preview Backend"
    
    check_pm2
    
    pm2 stop $SERVICE_NAME
    
    if [ $? -eq 0 ]; then
        print_success "Service stopped successfully"
    else
        print_error "Failed to stop service"
    fi
}

# Restart the service
restart_service() {
    print_header "Restarting Link Preview Backend"
    
    check_pm2
    
    pm2 restart $SERVICE_NAME
    
    if [ $? -eq 0 ]; then
        print_success "Service restarted successfully"
        pm2 status $SERVICE_NAME
    else
        print_error "Failed to restart service"
    fi
}

# Check service status
status_service() {
    print_header "Link Preview Backend Status"
    
    check_pm2
    
    pm2 status $SERVICE_NAME
    echo ""
    pm2 info $SERVICE_NAME
}

# View logs
view_logs() {
    print_header "Viewing Logs"
    
    check_pm2
    
    pm2 logs $SERVICE_NAME --lines 50
}

# Monitor service
monitor_service() {
    print_header "Monitoring Link Preview Backend"
    
    check_pm2
    
    print_info "Press Ctrl+C to exit monitoring"
    sleep 2
    pm2 monit
}

# Delete/Remove service
delete_service() {
    print_header "Removing Link Preview Backend"
    
    check_pm2
    
    print_warning "This will stop and remove the service from PM2"
    echo "Are you sure? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        pm2 delete $SERVICE_NAME
        pm2 save --force
        print_success "Service removed successfully"
    else
        print_info "Cancelled"
    fi
}

# Setup auto-start on boot
setup_startup() {
    print_header "Setting up Auto-Start on Boot"
    
    check_pm2
    
    pm2 save
    pm2 startup
    
    print_warning "You may need to run the command shown above with sudo"
    print_success "PM2 process list saved"
}

# Health check
health_check() {
    print_header "Health Check"
    
    print_info "Checking service health..."
    
    response=$(curl -s http://localhost:3001/api/health)
    
    if [ $? -eq 0 ]; then
        print_success "Service is healthy!"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        print_error "Service is not responding"
        print_info "Check if the service is running: ./manage-link-preview.sh status"
    fi
}

# Show menu
show_menu() {
    print_header "Link Preview Backend Management"
    
    echo "Select an option:"
    echo ""
    echo "  1) Start service"
    echo "  2) Stop service"
    echo "  3) Restart service"
    echo "  4) View status"
    echo "  5) View logs"
    echo "  6) Monitor service"
    echo "  7) Health check"
    echo "  8) Setup auto-start on boot"
    echo "  9) Remove service"
    echo "  0) Exit"
    echo ""
    echo -n "Enter choice [0-9]: "
    read -r choice
    
    case $choice in
        1) start_service ;;
        2) stop_service ;;
        3) restart_service ;;
        4) status_service ;;
        5) view_logs ;;
        6) monitor_service ;;
        7) health_check ;;
        8) setup_startup ;;
        9) delete_service ;;
        0) exit 0 ;;
        *) print_error "Invalid option"; show_menu ;;
    esac
}

# Main script
if [ $# -eq 0 ]; then
    # No arguments, show menu
    show_menu
else
    # Handle command line arguments
    case $1 in
        start) start_service ;;
        stop) stop_service ;;
        restart) restart_service ;;
        status) status_service ;;
        logs) view_logs ;;
        monitor) monitor_service ;;
        health) health_check ;;
        setup) setup_startup ;;
        delete) delete_service ;;
        *)
            print_error "Unknown command: $1"
            echo ""
            echo "Usage: $0 {start|stop|restart|status|logs|monitor|health|setup|delete}"
            echo "   or: $0           (interactive menu)"
            exit 1
            ;;
    esac
fi



