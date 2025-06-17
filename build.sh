#!/bin/bash

# Garmin Watch Face Build Script for SDK 8.1.1
# This script builds your analog watch face for Forerunner 970
# Usage: ./build.sh [options]
# Options:
#   --validate-only    Only validate code, don't build
#   --clean           Clean build directory first
#   --help            Show this help

set -e  # Exit on any error

# Parse command line arguments
VALIDATE_ONLY=false
CLEAN_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --validate-only)
            VALIDATE_ONLY=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --help)
            echo "Garmin Watch Face Build Script for SDK 8.1.1"
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --validate-only    Only validate code, don't build"
            echo "  --clean           Clean build directory first"
            echo "  --help            Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=== Garmin Analog Watch Face Build (SDK 8.1.1) ==="
if [ "$VALIDATE_ONLY" = true ]; then
    echo "🔍 Code validation mode"
else
    echo "🔨 Building for Forerunner 970..."
fi
echo ""

# Set up environment - Use the SDK in the project directory
export CIQ_HOME=/workspace/analog-face/connectiq-sdk
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$CIQ_HOME/bin

# Debug: Show environment
echo "🔧 Environment check:"
echo "CIQ_HOME: $CIQ_HOME"
echo "JAVA_HOME: $JAVA_HOME"
echo "Current directory: $(pwd)"
echo ""

# Check if MonkeyC compiler exists and is executable
if [ ! -f "$CIQ_HOME/bin/monkeyc" ]; then
    echo "❌ Error: MonkeyC compiler not found at $CIQ_HOME/bin/monkeyc"
    echo "Available files in $CIQ_HOME/bin/:"
    ls -la $CIQ_HOME/bin/ 2>/dev/null || echo "Directory does not exist"
    exit 1
fi

if [ ! -x "$CIQ_HOME/bin/monkeyc" ]; then
    echo "❌ Error: MonkeyC compiler is not executable"
    echo "Making it executable..."
    chmod +x $CIQ_HOME/bin/monkeyc
fi

# Test MonkeyC compiler
echo "🔍 Testing MonkeyC compiler..."
if ! $CIQ_HOME/bin/monkeyc --version > /dev/null 2>&1; then
    echo "❌ Error: MonkeyC compiler failed to run"
    echo "Trying to get version info..."
    $CIQ_HOME/bin/monkeyc --version 2>&1 || echo "Version check failed"
    exit 1
fi

echo "✅ MonkeyC compiler is working"

# Check if we're in the right directory
if [ ! -f "manifest.xml" ]; then
    echo "❌ Error: manifest.xml not found"
    echo "Current directory: $(pwd)"
    echo "Contents:"
    ls -la
    exit 1
fi

# Check if source files exist
if [ ! -d "source" ]; then
    echo "❌ Error: source directory not found"
    exit 1
fi

# Check if device files exist
if [ ! -f "Devices/fr970/compiler.json" ]; then
    echo "❌ Error: Device configuration not found at Devices/fr970/compiler.json"
    echo "Available device files:"
    ls -la Devices/fr970/ 2>/dev/null || echo "Devices/fr970 directory not found"
    exit 1
fi

# Create build directory
if [ "$VALIDATE_ONLY" = false ]; then
    echo "📁 Creating build directory..."
    mkdir -p build
    
    # Clean previous builds if requested
    if [ "$CLEAN_BUILD" = true ]; then
        echo "🧹 Cleaning previous builds..."
        rm -f build/*.prg
        rm -f build/*.debug.xml
    fi
fi

# Check for required source files
echo "🔍 Checking project files..."
required_files=("source/AnalogueApp.mc" "source/AnalogueView.mc")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Error: $file not found"
        echo "Available source files:"
        ls -la source/
        exit 1
    fi
done

# Check for API database files in SDK
API_DB="$CIQ_HOME/bin/api.db"
API_MIR="$CIQ_HOME/bin/api.mir"
DEVICES_XML="$CIQ_HOME/bin/devices.xml"

if [ ! -f "$API_DB" ]; then
    echo "❌ Warning: API database not found at $API_DB"
    echo "Available files in SDK bin:"
    ls -la $CIQ_HOME/bin/
fi

echo "✅ All required files found"

# Build source file list
SOURCE_FILES=()
for source_file in source/*.mc; do
    if [ -f "$source_file" ]; then
        SOURCE_FILES+=("$source_file")
    fi
done

# Build resource file list (if any)
RESOURCE_FILES=()
if [ -f "resources/layouts.xml" ]; then
    RESOURCE_FILES+=("resources/layouts.xml")
fi
if [ -f "resources/strings.xml" ]; then
    RESOURCE_FILES+=("resources/strings.xml")
fi

# Validation/Build command for SDK 8.1.1
echo "✅ Preparing build command..."

BUILD_CMD=(
    "$CIQ_HOME/bin/monkeyc"
    "--output" "build/analog-face.prg"
    "--device" "fr970"
    "--warn"
    "--typecheck" "2"
)

# Add API files if they exist
if [ -f "$API_DB" ]; then
    BUILD_CMD+=("--apidb" "$API_DB")
fi

if [ -f "$API_MIR" ]; then
    BUILD_CMD+=("--apimir" "$API_MIR")
fi

# Add devices.xml if it exists
if [ -f "$DEVICES_XML" ]; then
    BUILD_CMD+=("--devices" "$DEVICES_XML")
fi

# Add private key for signing (only for actual build, not validation)
if [ "$VALIDATE_ONLY" = false ] && [ -f "$CIQ_HOME/bin/developer_key.der" ]; then
    BUILD_CMD+=("--private-key" "$CIQ_HOME/bin/developer_key.der")
fi

# Add source files
BUILD_CMD+=("${SOURCE_FILES[@]}")

# Add resource files if any
if [ ${#RESOURCE_FILES[@]} -gt 0 ]; then
    BUILD_CMD+=("--rez" "${RESOURCE_FILES[@]}")
fi

# Run validation/build
if [ "$VALIDATE_ONLY" = true ]; then
    echo "✅ Validating code..."
    # For validation, we don't need output file
    VALIDATE_CMD=("${BUILD_CMD[@]}")
    # Remove output parameter for validation
    VALIDATE_CMD=("${VALIDATE_CMD[@]/--output}")
    VALIDATE_CMD=("${VALIDATE_CMD[@]/build\/analog-face.prg}")
    
    echo "Running validation: ${VALIDATE_CMD[*]}"
    if ! "${VALIDATE_CMD[@]}"; then
        echo "❌ Code validation failed!"
        exit 1
    fi
    echo "✅ Code validation passed!"
    echo ""
    echo "🎉 Validation complete! Code is ready for building."
    exit 0
else
    echo "🔨 Building watch face..."
    echo "Running build command:"
    echo "${BUILD_CMD[*]}"
    echo ""
    
    if "${BUILD_CMD[@]}"; then
        echo ""
        echo "🎉 Build successful!"
        echo "📦 Output file: build/analog-face.prg"
        
        # Show file info
        if [ -f "build/analog-face.prg" ]; then
            FILE_SIZE=$(ls -lh build/analog-face.prg | awk '{print $5}')
            echo "📏 File size: $FILE_SIZE"
            
            # Show file timestamp
            FILE_TIME=$(ls -l build/analog-face.prg | awk '{print $6, $7, $8}')
            echo "🕒 Built: $FILE_TIME"
        fi
        
        echo ""
        echo "📋 Build summary:"
        ls -la build/
        
        echo ""
        echo "🚀 Installation instructions:"
        echo "1. Connect your Forerunner 970 to your computer"
        echo "2. Copy build/analog-face.prg to GARMIN/APPS folder on your watch"
        echo "3. Safely eject your watch"
        echo "4. On your watch: Settings > Watch Face > Select your watchface"
        echo ""
        echo "💡 Pro tip: You can also test in the simulator first:"
        echo "   connectiq -d fr970 build/analog-face.prg"
        
    else
        echo ""
        echo "❌ Build failed!"
        echo "Check the error messages above for details"
        exit 1
    fi
fi