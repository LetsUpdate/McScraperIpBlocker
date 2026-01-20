#!/bin/bash

#######################################################################################
# KittyScan IP Blocker Script
# Downloads and blocks scanner IPs from KittyScanBlocklist using UFW
# Repository: https://github.com/LillySchramm/KittyScanBlocklist
#######################################################################################

# Configuration
BLOCKLIST_URL="https://raw.githubusercontent.com/LillySchramm/KittyScanBlocklist/main/ips-24.txt"
LOG_FILE="/var/log/kittyscan-blocker.log"
TEMP_FILE=$(mktemp /tmp/kittyscan-ips.XXXXXX)
UFW_COMMENT="KITTYSCAN"

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#######################################################################################
# Function: log_message
# Logs messages with timestamps to both console and log file
#######################################################################################
log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

#######################################################################################
# Function: check_root
# Ensures script is run with root privileges
#######################################################################################
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
        echo "Please run: sudo $0"
        exit 1
    fi
}

#######################################################################################
# Function: check_ufw
# Verifies UFW is installed and active
#######################################################################################
check_ufw() {
    log_message "INFO" "Checking UFW installation and status..."
    
    # Check if UFW is installed
    if ! command -v ufw &> /dev/null; then
        log_message "ERROR" "UFW is not installed. Please install it first:"
        echo -e "${RED}Run: sudo apt-get update && sudo apt-get install ufw${NC}"
        exit 1
    fi
    
    # Check if UFW is active
    if ! ufw status | grep -q "Status: active"; then
        log_message "WARN" "UFW is not currently active."
        echo -e "${YELLOW}Warning: UFW is installed but not enabled.${NC}"
        echo -e "${YELLOW}Before enabling UFW, ensure SSH is allowed to avoid lockout!${NC}"
        echo -e "${YELLOW}Run: sudo ufw allow ssh${NC}"
        echo -e "${YELLOW}Then: sudo ufw enable${NC}"
        exit 1
    fi
    
    log_message "INFO" "UFW is installed and active"
}

#######################################################################################
# Function: download_blocklist
# Downloads the latest IP blocklist from KittyScanBlocklist repository
#######################################################################################
download_blocklist() {
    log_message "INFO" "Downloading blocklist from ${BLOCKLIST_URL}..."
    
    if curl -s -f -o "$TEMP_FILE" "$BLOCKLIST_URL"; then
        local ip_count=$(wc -l < "$TEMP_FILE")
        log_message "INFO" "Successfully downloaded blocklist with ${ip_count} entries"
        return 0
    else
        log_message "ERROR" "Failed to download blocklist from ${BLOCKLIST_URL}"
        log_message "ERROR" "Please check your internet connection and the URL"
        cleanup
        exit 1
    fi
}

#######################################################################################
# Function: remove_old_rules
# Removes existing UFW rules tagged with KITTYSCAN comment
#######################################################################################
remove_old_rules() {
    log_message "INFO" "Removing old KITTYSCAN rules..."
    
    local removed_count=0
    
    # Get all rule numbers with KITTYSCAN comment (in reverse order to avoid index shifting)
    while IFS= read -r rule_num; do
        if [[ -n "$rule_num" ]]; then
            ufw --force delete "$rule_num" &> /dev/null
            ((removed_count++))
        fi
    done < <(ufw status numbered | grep "$UFW_COMMENT" | grep -oP '^\[\s*\K[0-9]+' | sort -rn)
    
    log_message "INFO" "Removed ${removed_count} old KITTYSCAN rules"
}

#######################################################################################
# Function: add_new_rules
# Adds UFW deny rules for each IP/subnet in the blocklist
#######################################################################################
add_new_rules() {
    log_message "INFO" "Adding new blocking rules..."
    
    local added_count=0
    local failed_count=0
    
    while IFS= read -r ip; do
        # Skip empty lines and comments
        if [[ -z "$ip" || "$ip" =~ ^# ]]; then
            continue
        fi
        
        # Trim whitespace
        ip=$(echo "$ip" | xargs)
        
        # Add deny rule with comment
        if ufw deny from "$ip" comment "$UFW_COMMENT" &> /dev/null; then
            ((added_count++))
        else
            log_message "WARN" "Failed to add rule for IP: ${ip}"
            ((failed_count++))
        fi
    done < "$TEMP_FILE"
    
    log_message "INFO" "Successfully added ${added_count} blocking rules"
    
    if [[ $failed_count -gt 0 ]]; then
        log_message "WARN" "Failed to add ${failed_count} rules"
    fi
}

#######################################################################################
# Function: cleanup
# Removes temporary files
#######################################################################################
cleanup() {
    if [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
        log_message "INFO" "Cleaned up temporary files"
    fi
}

#######################################################################################
# Function: display_summary
# Displays a summary of current blocking status
#######################################################################################
display_summary() {
    echo ""
    echo -e "${GREEN}=== KittyScan Blocker Summary ===${NC}"
    
    local rule_count=$(ufw status numbered | grep -c "$UFW_COMMENT" || echo "0")
    echo -e "Active KITTYSCAN rules: ${GREEN}${rule_count}${NC}"
    
    echo ""
    echo "To view all blocking rules, run:"
    echo "  sudo ufw status numbered | grep KITTYSCAN"
    echo ""
    echo "To view full UFW status, run:"
    echo "  sudo ufw status numbered"
    echo ""
    echo -e "${GREEN}Update completed successfully!${NC}"
}

#######################################################################################
# Main execution
#######################################################################################
main() {
    log_message "INFO" "========== KittyScan Blocker Started =========="
    
    # Check prerequisites
    check_root
    check_ufw
    
    # Download and process blocklist
    download_blocklist
    
    # Update UFW rules
    remove_old_rules
    add_new_rules
    
    # Cleanup
    cleanup
    
    # Display summary
    display_summary
    
    log_message "INFO" "========== KittyScan Blocker Finished =========="
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function
main
