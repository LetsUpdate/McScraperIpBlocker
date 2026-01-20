#!/bin/bash

#######################################################################################
# KittyScan IP Blocker - Installation Script
# Installs and configures the KittyScan IP blocking system
#######################################################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
SCRIPT_SOURCE="./block-scanners.sh"
SCRIPT_DEST="/usr/local/bin/block-scanners.sh"
SERVICE_SOURCE="./kittyscan-blocker.service"
SERVICE_DEST="/etc/systemd/system/kittyscan-blocker.service"
CRONTAB_TEMPLATE="./crontab-template.txt"

#######################################################################################
# Function: print_header
# Displays a formatted header
#######################################################################################
print_header() {
    echo -e "${BLUE}"
    echo "======================================================================"
    echo "  KittyScan IP Blocker - Installation Script"
    echo "======================================================================"
    echo -e "${NC}"
}

#######################################################################################
# Function: check_root
# Ensures script is run with root privileges
#######################################################################################
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This installation script must be run as root or with sudo${NC}"
        echo "Please run: sudo ./install.sh"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Running with root privileges"
}

#######################################################################################
# Function: check_ufw_installed
# Verifies UFW is installed
#######################################################################################
check_ufw_installed() {
    echo -n "Checking UFW installation... "
    
    if ! command -v ufw &> /dev/null; then
        echo -e "${RED}✗${NC}"
        echo ""
        echo -e "${RED}UFW is not installed on this system.${NC}"
        echo ""
        echo "To install UFW, run:"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install ufw"
        echo ""
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC}"
}

#######################################################################################
# Function: check_ufw_enabled
# Checks if UFW is enabled and warns if not
#######################################################################################
check_ufw_enabled() {
    echo -n "Checking UFW status... "
    
    if ! ufw status | grep -q "Status: active"; then
        echo -e "${YELLOW}⚠${NC}"
        echo ""
        echo -e "${YELLOW}WARNING: UFW is installed but not enabled!${NC}"
        echo ""
        echo -e "${RED}IMPORTANT: Before enabling UFW, you MUST allow SSH to avoid lockout!${NC}"
        echo ""
        echo "To safely enable UFW, run these commands:"
        echo "  sudo ufw allow ssh"
        echo "  sudo ufw allow 22/tcp"
        echo "  sudo ufw enable"
        echo ""
        echo -e "${YELLOW}After enabling UFW, run this installation script again.${NC}"
        echo ""
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC}"
}

#######################################################################################
# Function: check_dependencies
# Verifies all required dependencies are installed
#######################################################################################
check_dependencies() {
    echo -n "Checking for curl... "
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}✗${NC}"
        echo ""
        echo -e "${RED}curl is not installed.${NC}"
        echo "To install curl, run: sudo apt-get install curl"
        exit 1
    fi
    
    echo -e "${GREEN}✓${NC}"
}

#######################################################################################
# Function: check_required_files
# Ensures all required files are present
#######################################################################################
check_required_files() {
    echo "Checking required files..."
    
    local missing_files=0
    
    if [[ ! -f "$SCRIPT_SOURCE" ]]; then
        echo -e "  ${RED}✗${NC} Missing: $SCRIPT_SOURCE"
        ((missing_files++))
    else
        echo -e "  ${GREEN}✓${NC} Found: $SCRIPT_SOURCE"
    fi
    
    if [[ ! -f "$SERVICE_SOURCE" ]]; then
        echo -e "  ${RED}✗${NC} Missing: $SERVICE_SOURCE"
        ((missing_files++))
    else
        echo -e "  ${GREEN}✓${NC} Found: $SERVICE_SOURCE"
    fi
    
    if [[ ! -f "$CRONTAB_TEMPLATE" ]]; then
        echo -e "  ${YELLOW}⚠${NC} Missing: $CRONTAB_TEMPLATE (optional)"
    else
        echo -e "  ${GREEN}✓${NC} Found: $CRONTAB_TEMPLATE"
    fi
    
    if [[ $missing_files -gt 0 ]]; then
        echo ""
        echo -e "${RED}Error: Missing required files. Please ensure you're running this script from the project directory.${NC}"
        exit 1
    fi
}

#######################################################################################
# Function: install_script
# Copies the main script to the system directory
#######################################################################################
install_script() {
    echo -n "Installing blocking script to $SCRIPT_DEST... "
    
    cp "$SCRIPT_SOURCE" "$SCRIPT_DEST"
    chmod +x "$SCRIPT_DEST"
    
    echo -e "${GREEN}✓${NC}"
}

#######################################################################################
# Function: install_service
# Installs and enables the systemd service
#######################################################################################
install_service() {
    echo -n "Installing systemd service... "
    
    cp "$SERVICE_SOURCE" "$SERVICE_DEST"
    
    echo -e "${GREEN}✓${NC}"
    
    echo -n "Reloading systemd daemon... "
    systemctl daemon-reload
    echo -e "${GREEN}✓${NC}"
    
    echo -n "Enabling kittyscan-blocker service... "
    systemctl enable kittyscan-blocker.service &> /dev/null
    echo -e "${GREEN}✓${NC}"
}

#######################################################################################
# Function: setup_cron
# Offers to configure cron jobs
#######################################################################################
setup_cron() {
    echo ""
    echo -e "${BLUE}Cron Job Configuration${NC}"
    echo "Would you like to automatically add cron jobs for scheduled updates?"
    echo -n "Add cron jobs? (y/n): "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Adding cron jobs to root crontab..."
        
        # Create temporary crontab file
        crontab -l > /tmp/current_crontab 2>/dev/null || true
        
        # Check if entries already exist
        if grep -q "block-scanners.sh" /tmp/current_crontab 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC} Cron jobs for block-scanners.sh already exist. Skipping..."
        else
            # Add new entries
            echo "" >> /tmp/current_crontab
            echo "# KittyScan IP Blocker - Auto-generated entries" >> /tmp/current_crontab
            echo "@reboot /usr/local/bin/block-scanners.sh" >> /tmp/current_crontab
            echo "0 3 * * * /usr/local/bin/block-scanners.sh" >> /tmp/current_crontab
            
            # Install new crontab
            crontab /tmp/current_crontab
            echo -e "${GREEN}✓${NC} Cron jobs added successfully"
        fi
        
        rm -f /tmp/current_crontab
    else
        echo ""
        echo "To manually add cron jobs, edit root crontab:"
        echo "  sudo crontab -e"
        echo ""
        echo "And add these lines:"
        echo "  @reboot /usr/local/bin/block-scanners.sh"
        echo "  0 3 * * * /usr/local/bin/block-scanners.sh"
        echo ""
        echo "See crontab-template.txt for more options."
    fi
}

#######################################################################################
# Function: create_log_file
# Creates the log file with proper permissions
#######################################################################################
create_log_file() {
    echo -n "Creating log file... "
    
    touch /var/log/kittyscan-blocker.log
    chmod 644 /var/log/kittyscan-blocker.log
    
    echo -e "${GREEN}✓${NC}"
}

#######################################################################################
# Function: run_initial_update
# Runs the blocking script for the first time
#######################################################################################
run_initial_update() {
    echo ""
    echo -e "${BLUE}Running initial blocklist update...${NC}"
    echo ""
    
    "$SCRIPT_DEST"
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✓${NC} Initial update completed successfully"
    else
        echo ""
        echo -e "${YELLOW}⚠${NC} Initial update encountered issues. Check the log at /var/log/kittyscan-blocker.log"
    fi
}

#######################################################################################
# Function: display_success
# Displays installation success message and next steps
#######################################################################################
display_success() {
    echo ""
    echo -e "${GREEN}"
    echo "======================================================================"
    echo "  Installation completed successfully!"
    echo "======================================================================"
    echo -e "${NC}"
    echo ""
    echo "Next steps and verification:"
    echo ""
    echo "1. View active blocking rules:"
    echo "   sudo ufw status numbered | grep KITTYSCAN"
    echo ""
    echo "2. Check the log file:"
    echo "   sudo tail -f /var/log/kittyscan-blocker.log"
    echo ""
    echo "3. Verify systemd service:"
    echo "   sudo systemctl status kittyscan-blocker"
    echo ""
    echo "4. Manually trigger an update:"
    echo "   sudo /usr/local/bin/block-scanners.sh"
    echo ""
    echo "5. View cron jobs:"
    echo "   sudo crontab -l | grep block-scanners"
    echo ""
    echo -e "${BLUE}The blocker will run automatically:${NC}"
    echo "  - At system boot (via systemd)"
    echo "  - Daily at 3 AM (via cron, if configured)"
    echo ""
    echo -e "${YELLOW}Security reminder:${NC}"
    echo "  - Ensure SSH access is allowed in UFW"
    echo "  - Monitor the blocklist to avoid false positives"
    echo "  - Review /var/log/kittyscan-blocker.log regularly"
    echo ""
}

#######################################################################################
# Main installation process
#######################################################################################
main() {
    print_header
    
    echo "This script will install KittyScan IP Blocker on your system."
    echo ""
    
    # Run all checks
    check_root
    check_ufw_installed
    check_ufw_enabled
    check_dependencies
    check_required_files
    
    echo ""
    echo -e "${BLUE}Starting installation...${NC}"
    echo ""
    
    # Install components
    install_script
    install_service
    create_log_file
    
    # Configure cron
    setup_cron
    
    # Run initial update
    run_initial_update
    
    # Display success message
    display_success
}

# Run main function
main
