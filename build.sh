#!/bin/bash

# Argument parsing
ISO_SOURCE=""
ISO_MODIFIED=""
PRESEED_FILE=""
DEBUG=false
CHECKSUM=false
TMP_DIR=""

function usage() {
    echo "Usage: $0 --in <source_iso> --out <modified_iso> --preseed <preseed_file> [--debug] [--checksum]"
    echo "Or:    $0 in=<source_iso> out=<modified_iso> preseed=<preseed_file> [debug] [checksum]"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --in)
            ISO_SOURCE="$2"
            shift 2
            ;;
        --out)
            ISO_MODIFIED="$2"
            shift 2
            ;;
        --preseed)
            PRESEED_FILE="$2"
            shift 2
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --checksum)
            CHECKSUM=true
            shift
            ;;
        in=*)
            ISO_SOURCE="${1#*=}"
            shift
            ;;
        out=*)
            ISO_MODIFIED="${1#*=}"
            shift
            ;;
        preseed=*)
            PRESEED_FILE="${1#*=}"
            shift
            ;;
        debug)
            DEBUG=true
            shift
            ;;
        checksum)
            CHECKSUM=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$ISO_SOURCE" || -z "$ISO_MODIFIED" || -z "$PRESEED_FILE" ]]; then
    echo "Missing required arguments."
    usage
fi

if $DEBUG; then
    set -x
    LOG="/dev/stdout"
else
    LOG="/dev/null"
fi

ISO_EXTRACT_DIR="isofiles"

echo "Installing required packages..."
sudo apt install -y xorriso isolinux curl >"$LOG" 2>&1

# If the ISO source is a remote URL, download it first
if [[ "$ISO_SOURCE" =~ ^https?:// ]]; then
    TMP_DIR=$(mktemp -d)
    TMP_ISO="$TMP_DIR/source.iso"
    echo "Downloading ISO from $ISO_SOURCE to $TMP_ISO..."
    curl -L "$ISO_SOURCE" -o "$TMP_ISO"
    ISO_SOURCE="$TMP_ISO"
fi

echo "Creating extraction directory: $ISO_EXTRACT_DIR"
mkdir -p "$ISO_EXTRACT_DIR" >"$LOG" 2>&1

echo "Extracting ISO contents from $ISO_SOURCE..."
xorriso -osirrox on -indev "$ISO_SOURCE" -extract / "$ISO_EXTRACT_DIR" >"$LOG" 2>&1

echo "Modifying permissions for install.amd/"
chmod +w -R "$ISO_EXTRACT_DIR/install.amd/" >"$LOG" 2>&1

echo "Extracting and patching initrd with $PRESEED_FILE..."
if [[ ! -f "$PRESEED_FILE" ]]; then
    echo "Error: Preseed file '$PRESEED_FILE' not found."
    exit 1
fi
gunzip "$ISO_EXTRACT_DIR/install.amd/initrd.gz" >"$LOG" 2>&1
echo $PRESEED_FILE | cpio -H newc -o -A -F "$ISO_EXTRACT_DIR/install.amd/initrd" >"$LOG" 2>&1
gzip "$ISO_EXTRACT_DIR/install.amd/initrd" >"$LOG" 2>&1

echo "Restoring permissions for install.amd/"
chmod -w -R "$ISO_EXTRACT_DIR/install.amd/" >"$LOG" 2>&1

echo "Updating boot menu labels..."
sed -i 's/menu label ^Install/menu label ^Preseed Install/' "$ISO_EXTRACT_DIR/isolinux/txt.cfg" >"$LOG" 2>&1

echo "Setting default install mode..."
sed -i 's/default vesamenu.c32/default install/' "$ISO_EXTRACT_DIR/isolinux/isolinux.cfg" >"$LOG" 2>&1

echo "Updating md5sum.txt..."
chmod +w "$ISO_EXTRACT_DIR/md5sum.txt" >"$LOG" 2>&1
find "$ISO_EXTRACT_DIR" -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > "$ISO_EXTRACT_DIR/md5sum.txt"
chmod -w "$ISO_EXTRACT_DIR/md5sum.txt" >"$LOG" 2>&1

echo "Creating modified ISO: $ISO_MODIFIED"
xorriso -as mkisofs \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -c isolinux/boot.cat \
    -b isolinux/isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o "$ISO_MODIFIED" \
    "$ISO_EXTRACT_DIR/" >"$LOG" 2>&1

echo "ISO creation completed: $ISO_MODIFIED"

if $CHECKSUM; then
    echo "Generating checksums for $ISO_MODIFIED..."
    MD5_SUM=$(md5sum "$ISO_MODIFIED" | awk '{print $1}')
    SHA1_SUM=$(sha1sum "$ISO_MODIFIED" | awk '{print $1}')
    SHA256_SUM=$(sha256sum "$ISO_MODIFIED" | awk '{print $1}')
    SHA512_SUM=$(sha512sum "$ISO_MODIFIED" | awk '{print $1}')

    echo "Checksums for $ISO_MODIFIED:"
    echo "MD5:    $MD5_SUM"
    echo "SHA1:   $SHA1_SUM"
    echo "SHA256: $SHA256_SUM"
    echo "SHA512: $SHA512_SUM"
fi

# Cleanup temp dir if created
if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    echo "Cleaning up temporary directory: $TMP_DIR"
    rm -rf "$TMP_DIR"
fi
