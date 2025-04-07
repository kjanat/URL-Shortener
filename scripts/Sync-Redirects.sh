#!/bin/bash
#
# DESCRIPTION:
#   This script synchronizes the redirects between a JSON file and a YAML file.
#   It checks which file is newer and updates the other file with any missing entries.
#   If both files are the same, it does nothing.
#   If the newer file is the YAML file, it converts it to JSON and writes it to the JSON file.
#   If the newer file is the JSON file, it converts it to YAML and writes it to the YAML file.
#
# SYNOPSIS:
#   Synchronize redirects between JSON and YAML files.
#
# USAGE:
#   ./redirects-sync.sh [options]
#
# OPTIONS:
#   -g, --git-root    The root directory of the Git repository. Defaults to the parent directory of the script.
#   -j, --json-file   The path to the JSON file containing redirects.
#   -y, --yaml-file   The path to the YAML file containing redirects.
#   -v, --verbose     Enable verbose output.
#   -d, --debug       Enable debug output.
#   -h, --help        Display this help message and exit.
#
# DEPENDENCIES:
#   - jq (for JSON processing)
#   - yq (for YAML processing)
#
# EXAMPLE:
#   ./redirects-sync.sh --json-file "/path/to/redirects.json" --yaml-file "/path/to/redirects.yaml"

set -e

# Function to display usage information
show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo "Synchronize redirects between JSON and YAML files."
    echo ""
    echo "Options:"
    echo "  -g, --git-root DIR     The root directory of the Git repository"
    echo "  -j, --json-file FILE   The path to the JSON file containing redirects"
    echo "  -y, --yaml-file FILE   The path to the YAML file containing redirects"
    echo "  -v, --verbose          Enable verbose output"
    echo "  -d, --debug            Enable debug output"
    echo "  -n, --dry-run          Show what would be done without making changes"
    echo "  -h, --help             Display this help message and exit"
}

# Function for verbose output
verbose() {
    if [ "$VERBOSE" = true ]; then
        echo "[INFO] $1"
    fi
}

# Function for debug output
debug() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $1"
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
    if ! command_exists jq; then
        echo "Error: 'jq' is required but not installed. Please install it first."
        exit 1
    fi
    
    if ! command_exists yq; then
        echo "Error: 'yq' is required but not installed. Please install it first."
        exit 1
    fi
}

# Initialize variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT="$(dirname "$SCRIPT_DIR")"
JSON_FILE=""
YAML_FILE=""
VERBOSE=false
DEBUG=false
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--git-root)
            GIT_ROOT="$2"
            shift 2
            ;;
        -j|--json-file)
            JSON_FILE="$2"
            shift 2
            ;;
        -y|--yaml-file)
            YAML_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--debug)
            DEBUG=true
            VERBOSE=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Set default file paths if not provided
if [ -z "$JSON_FILE" ]; then
    JSON_FILE="$GIT_ROOT/redirects.json"
fi

if [ -z "$YAML_FILE" ]; then
    YAML_FILE="$GIT_ROOT/redirects.yml"
fi

# Check if files exist
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: JSON file '$JSON_FILE' does not exist."
    exit 1
fi

if [ ! -f "$YAML_FILE" ]; then
    echo "Error: YAML file '$YAML_FILE' does not exist."
    exit 1
fi

# Log parameters
debug "GIT_ROOT: $GIT_ROOT"
debug "JSON_FILE: $JSON_FILE"
debug "YAML_FILE: $YAML_FILE"
debug "VERBOSE: $VERBOSE"
debug "DEBUG: $DEBUG"
debug "DRY_RUN: $DRY_RUN"

# Check dependencies
verbose "Checking dependencies"
check_dependencies

# Get file modification times
verbose "Getting file modification times"
JSON_MTIME=$(stat -c %Y "$JSON_FILE" 2>/dev/null || stat -f %m "$JSON_FILE")
YAML_MTIME=$(stat -c %Y "$YAML_FILE" 2>/dev/null || stat -f %m "$JSON_FILE")
debug "JSON last modified: $(date -r "$JSON_MTIME" 2>/dev/null || date -r "$JSON_FILE")"
debug "YAML last modified: $(date -r "$YAML_MTIME" 2>/dev/null || date -r "$YAML_FILE")"

# Count entries in files
JSON_COUNT=$(jq 'length' "$JSON_FILE")
YAML_COUNT=$(yq 'length' "$YAML_FILE")
debug "JSON entries count: $JSON_COUNT"
debug "YAML entries count: $YAML_COUNT"

# Determine which file is newer and sync accordingly
if [ "$JSON_MTIME" -gt "$YAML_MTIME" ]; then
    verbose "JSON file is newer than YAML file"
    
    HAS_CHANGES=false
    
    if [ "$YAML_COUNT" -lt "$JSON_COUNT" ]; then
        echo "JSON file has more entries than YAML file"
        HAS_CHANGES=true
    elif [ "$YAML_COUNT" -gt "$JSON_COUNT" ]; then
        echo "YAML file has more entries than JSON file"
        HAS_CHANGES=true
    else
        echo "JSON file has the same number of entries as YAML file"
        # Compare keys in both files
        # This is simplified and might need to be expanded based on your exact data structure
        JSON_KEYS=$(jq -r 'keys[]' "$JSON_FILE" | sort)
        YAML_KEYS=$(yq -r 'keys[]' "$YAML_FILE" | sort)
        
        if [ "$JSON_KEYS" != "$YAML_KEYS" ]; then
            debug "Key differences found between JSON and YAML"
            HAS_CHANGES=true
        fi
    fi
    
    if [ "$HAS_CHANGES" = true ]; then
        echo "Found differences that need to be synchronized"
        
        if [ "$DRY_RUN" = false ]; then
            verbose "Updating YAML file from JSON data"
            cat "$JSON_FILE" | yq -y '.' > "$YAML_FILE"
            echo "Synchronized JSON to YAML."
        else
            echo "[DRY RUN] Would synchronize JSON to YAML."
        fi
    else
        echo "No changes needed for synchronization."
    fi
    
elif [ "$YAML_MTIME" -gt "$JSON_MTIME" ]; then
    verbose "YAML file is newer than JSON file"
    
    HAS_CHANGES=false
    
    if [ "$JSON_COUNT" -lt "$YAML_COUNT" ]; then
        echo "YAML file has more entries than JSON file"
        HAS_CHANGES=true
    elif [ "$JSON_COUNT" -gt "$YAML_COUNT" ]; then
        echo "JSON file has more entries than YAML file"
        HAS_CHANGES=true
    else
        echo "YAML file has the same number of entries as JSON file"
        # Compare keys in both files
        JSON_KEYS=$(jq -r 'keys[]' "$JSON_FILE" | sort)
        YAML_KEYS=$(yq -r 'keys[]' "$YAML_FILE" | sort)
        
        if [ "$JSON_KEYS" != "$YAML_KEYS" ]; then
            debug "Key differences found between YAML and JSON"
            HAS_CHANGES=true
        fi
    fi
    
    if [ "$HAS_CHANGES" = true ]; then
        echo "Found differences that need to be synchronized"
        
        if [ "$DRY_RUN" = false ]; then
            verbose "Updating JSON file from YAML data"
            yq -j '.' "$YAML_FILE" > "$JSON_FILE"
            echo "Synchronized YAML to JSON."
        else
            echo "[DRY RUN] Would synchronize YAML to JSON."
        fi
    else
        echo "No changes needed for synchronization."
    fi
    
else
    echo "Both files are already synchronized."
    debug "JSON and YAML timestamps are identical: $(date -r "$JSON_MTIME" 2>/dev/null || date -r "$JSON_FILE")"
fi

verbose "Redirects synchronization process completed"
