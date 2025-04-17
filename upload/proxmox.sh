#!/bin/bash

# Default values
STORAGE="local"
DEBUG=false

function usage() {
    echo "Usage: $0 --url <host> --nodes <nodes> --iso <path> --token-id <id> [--token-secret <secret>] [--debug]"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --url)
            PROXMOX_HOST="$2"
            shift 2
            ;;
        --nodes)
            PROXMOX_NODES="$2"
            shift 2
            ;;
        --storage)
            STORAGE="$2"
            shift 2
            ;;
        --iso)
            ISO_PATH="$2"
            shift 2
            ;;
        --token-id)
            TOKEN_ID="$2"
            shift 2
            ;;
        --token-secret)
            API_SECRET="$2"
            shift 2
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        -*|--*)
            echo "Unknown option $1"
            usage
            ;;
        *)
            shift
            ;;
    esac
done

# Check required variables
if [[ -z "$PROXMOX_HOST" || -z "$PROXMOX_NODES" || -z "$ISO_PATH" || -z "$TOKEN_ID" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

if [[ -z "$API_SECRET" ]]; then
    read -s -p "API Token Secret: " API_SECRET
    shift
fi

# Debug output (if enabled)
if [[ "$DEBUG" == true ]]; then
    echo "[DEBUG] PROXMOX_HOST=$PROXMOX_HOST"
    echo "[DEBUG] PROXMOX_NODES=$PROXMOX_NODES"
    echo "[DEBUG] STORAGE=$STORAGE"
    echo "[DEBUG] ISO_PATH=$ISO_PATH"
    echo "[DEBUG] TOKEN_ID=$TOKEN_ID"
    echo "[DEBUG] TOKEN_SECRET=****"
fi

# Check if the ISO file exists
if [[ ! -f "$ISO_PATH" ]]; then
    echo "Error: The file \"$ISO_PATH\" does not exist."
    exit 1
fi

# Get the file name
ISO_NAME=$(basename "$ISO_PATH")

echo -e "\nUploading..."

# Upload the file
RESPONSE=$(curl -k -X POST "https://$PROXMOX_HOST:8006/api2/json/nodes/$PROXMOX_NODES/storage/$STORAGE/upload" \
    -H "Authorization: PVEAPIToken=$TOKEN_ID=$API_SECRET" \
    -F "content=iso" \
    -F "filename=@$ISO_PATH" 2>&1)

if [[ $? -ne 0 ]]; then
    echo "Error during upload: $RESPONSE"
    exit 1
fi

echo "Upload completed."
