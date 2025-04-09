#!/bin/bash
# DESCRIPTION:
#   Synchronizes redirects between a JSON and YAML file, prioritizing the file with the most entries.
# USAGE:
#   ./redirects-sync.sh [options]
# OPTIONS:
#   -j, --json-file   The path to the JSON file containing redirects.
#   -y, --yaml-file   The path to the YAML file containing redirects.
#   -v, --verbose     Enable verbose output.
#   -n, --dry-run     Show what would be done without making changes
#   -h, --help        Display this help message and exit.
# DEPENDENCIES:
#   - yq (for YAML and JSON processing)

set -e

# Function to display usage information
show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo "Synchronize redirects between JSON and YAML files."
    echo ""
    echo "Options:"
    echo "  -j, --json-file FILE   The path to the JSON file containing redirects"
    echo "  -y, --yaml-file FILE   The path to the YAML file containing redirects"
    echo "  -v, --verbose          Enable verbose output"
    echo "  -n, --dry-run          Show what would be done without making changes"
    echo "  -h, --help             Display this help message and exit"
}

# Function for verbose output
verbose() {
    [ "$VERBOSE" = true ] && echo "[VERBOSE] $1"
}

error() {
    # Make error red
    echo -e "\e[31m [ERROR]  $1\e[0m" >&2
    # Stop script execution
    exit 1
}

warning() {
    # Make warning yellow
    echo -e "\e[33m[WARNING] $1\e[0m" >&2
}

success() {
    # Make success green
    echo -e "\e[32m[SUCCESS] $1\e[0m"
}

dry_run() {
    # Make dry run output blue
    [ "$DRY_RUN" = true ] && echo -e "\e[34m[DRY RUN] $1\e[0m"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
    command_exists yq || { echo "Error: 'yq' is required. Install using 'snap install yq'."; exit 1; }
}

# Initialize variables
GIT_ROOT="$(dirname "$(dirname "$(readlink -f "$0")")")"
JSON_FILE="$GIT_ROOT/redirects.json"
YAML_FILE="$GIT_ROOT/redirects.yml"
VERBOSE=false
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -j|--json-file) JSON_FILE="$2"; shift 2 ;;
        -y|--yaml-file) YAML_FILE="$2"; shift 2 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -n|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

verbose "Arguments:"
verbose "GIT_ROOT:  $GIT_ROOT"
verbose "JSON_FILE: $JSON_FILE"
verbose "YAML_FILE: $YAML_FILE"
verbose "VERBOSE:   $VERBOSE"
verbose "DRY_RUN:   $DRY_RUN"

# Check dependencies
verbose "Checking dependencies"
check_dependencies

# Check if files exist
[ ! -f "$JSON_FILE" ] && { error "JSON file '$JSON_FILE' does not exist."; exit 1; }
[ ! -f "$YAML_FILE" ] && { error "YAML file '$YAML_FILE' does not exist."; exit 1; }

# Count entries in files
JSON_COUNT=$(yq 'length' "$JSON_FILE")
YAML_COUNT=$(yq 'length' "$YAML_FILE")

# Get file modification times
JSON_MTIME=$(stat -c %Y "$JSON_FILE" 2>/dev/null || stat -f %m "$JSON_FILE")
YAML_MTIME=$(stat -c %Y "$YAML_FILE" 2>/dev/null || stat -f %m "$YAML_FILE")

# Determine which file has more entries
if [ "$JSON_COUNT" -ge "$YAML_COUNT" ]; then
    SOURCE_FILE="$JSON_FILE"
    SOURCE_TYPE="JSON"
    SOURCE_COUNT="$JSON_COUNT"
    SOURCE_MTIME="$JSON_MTIME"
    DEST_FILE="$YAML_FILE"
    DEST_TYPE="YAML"
    DEST_MTIME="$YAML_MTIME"
    UPDATE_COMMAND='yq "$JSON_FILE" --input-format json --prettyPrint --output-format yaml'
else
    SOURCE_FILE="$YAML_FILE"
    SOURCE_TYPE="YAML"
    SOURCE_COUNT="$YAML_COUNT"
    SOURCE_MTIME="$YAML_MTIME"
    DEST_FILE="$JSON_FILE"
    DEST_TYPE="JSON"
    DEST_MTIME="$JSON_MTIME"
    UPDATE_COMMAND='yq "$YAML_FILE" --input-format yaml --prettyPrint --output-format json'
fi

# Check if the file with more entries is older
if [ "$SOURCE_MTIME" -lt "$DEST_MTIME" ]; then
    warning "The $SOURCE_TYPE file ('$SOURCE_FILE') has more entries but is older than the $DEST_TYPE file ('$DEST_FILE')."
fi

# Synchronize if needed
if [ "$JSON_COUNT" -ne "$YAML_COUNT" ]; then
    if [ "$DRY_RUN" = true ]; then
        dry_run "Would have re-created '$DEST_FILE' from '$SOURCE_FILE'."
    else
        verbose "Re-creating $DEST_TYPE file ('$DEST_FILE') from $SOURCE_TYPE file ('$SOURCE_FILE')."
        verbose "Running command: $UPDATE_COMMAND"
        eval "$UPDATE_COMMAND" > "$DEST_FILE"
        success "Successfully re-created '$DEST_FILE' from '$SOURCE_FILE'."
    fi
else
    success "Files are already synchronized."
fi

success "Synchronization process completed."
