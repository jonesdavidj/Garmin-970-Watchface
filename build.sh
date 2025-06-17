#!/bin/bash

# Garmin Watch Face Build Script
# This script builds your analog watch face for Forerunner 970
# Usage: ./build.sh [options]
# Options:
#   --validate-only    Only validate code, don't build
#   --clean           Clean build directory first
#   --debug           Enable debug output
#   --help            Show this help

set -e  # Exit on any error

# Parse command line arguments
VALIDATE_ONLY=false
CLEAN_BUILD=false
DEBUG=false

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
        --debug)
            DEBUG=true
            shift
            ;;
        --help)
            echo "Garmin Watch Face Build Script"
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --validate-only    Only validate code, don't build"
            echo "  --clean           Clean build directory first"
            echo "  --debug           Enable debug output"
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

echo "=== Garmin Analog Watch Face Build ==="
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

# Debug mode
if [ "$DEBUG" = true ]; then
    set -x  # Enable command tracing
fi

# Debug: Show environment
echo "🔧 Environment check:"
echo "CIQ_HOME: $CIQ_HOME"
echo "JAVA_HOME: $JAVA_HOME"
echo "Current directory: $(pwd)"
echo "Java version:"
java -version 2>&1 | head -1
echo ""

# Comprehensive SDK check
echo "🔍 SDK Installation Check:"
if [ ! -d "$CIQ_HOME" ]; then
    echo "❌ Error: CIQ_HOME directory not found at $CIQ_HOME"
    exit 1
fi

echo "✅ SDK directory found"

# List SDK contents for debugging
if [ "$DEBUG" = true ]; then
    echo "SDK directory contents:"
    ls -la $CIQ_HOME/
    echo ""
    echo "SDK bin directory contents:"
    ls -la $CIQ_HOME/bin/ | head -10
    echo ""
fi

# Check if MonkeyC compiler exists and is executable
if [ ! -f "$CIQ_HOME/bin/monkeyc" ]; then
    echo "❌ Error: MonkeyC compiler not found at $CIQ_HOME/bin/monkeyc"
    echo "Available files in $CIQ_HOME/bin/:"
    ls -la $CIQ_HOME/bin/ 2>/dev/null || echo "Directory does not exist"
    exit 1
fi

if [ ! -x "$CIQ_HOME/bin/monkeyc" ]; then
    echo "⚠️  Warning: MonkeyC compiler is not executable, fixing..."
    chmod +x $CIQ_HOME/bin/monkeyc
fi

# Test MonkeyC compiler
echo "🔍 Testing MonkeyC compiler..."
if ! $CIQ_HOME/bin/monkeyc --version > /dev/null 2>&1; then
    echo "❌ Error: MonkeyC compiler failed to run"
    echo "Trying to get version info..."
    $CIQ_HOME/bin/monkeyc --version 2>&1 || echo "Version check failed"
    
    # Additional debugging
    echo "File permissions:"
    ls -la $CIQ_HOME/bin/monkeyc
    echo "File type:"
    file $CIQ_HOME/bin/monkeyc
    exit 1
fi

MONKEYC_VERSION=$($CIQ_HOME/bin/monkeyc --version 2>&1 | head -1)
echo "✅ MonkeyC compiler is working: $MONKEYC_VERSION"

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

# Check device configuration - for SDK 8.x, we need compiler.json
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

echo "✅ All required files found"

# For SDK 8.x, the build command syntax is different
# Build command for SDK 8.x
BUILD_CMD=(
    "$CIQ_HOME/bin/monkeyc"
    "-o" "build/analog-face.prg"
    "-m" "manifest.xml"
    "-d" "fr970"
    "-w"
)

# Add private key if it exists
if [ -f "$CIQ_HOME/bin/developer_key.der" ]; then
    BUILD_CMD+=("-y" "$CIQ_HOME/bin/developer_key.der")
else
    echo "⚠️  Warning: No private key found, creating one..."
    cd $CIQ_HOME/bin && \
    openssl genrsa -out developer_key.pem 4096 && \
    openssl rsa -in developer_key.pem -outform DER -out developer_key.der
    BUILD_CMD+=("-y" "$CIQ_HOME/bin/developer_key.der")
fi

# Add source files
for source_file in source/*.mc; do
    if [ -f "$source_file" ]; then
        BUILD_CMD+=("$source_file")
    fi
done

# Add resource files
if [ -f "resources/layouts.xml" ]; then
    BUILD_CMD+=("resources/layouts.xml")
fi
if [ -f "resources/strings.xml" ]; then
    BUILD_CMD+=("resources/strings.xml")
fi

# Validate/Build
if [ "$VALIDATE_ONLY" = true ]; then
    echo "✅ Validating code..."
    # For validation, we use the same command but with a temp output file
    VALIDATE_CMD=("${BUILD_CMD[@]}")
    # Replace output with a temp file for validation
    for i in "${!VALIDATE_CMD[@]}"; do
        if [[ "${VALIDATE_CMD[$i]}" == "build/analog-face.prg" ]]; then
            VALIDATE_CMD[$i]="/tmp/validation.prg"
        fi
    done
else
    echo "🔨 Building watch face..."
fi

echo "Running command:"
if [ "$VALIDATE_ONLY" = true ]; then
    echo "${VALIDATE_CMD[*]}"
else
    echo "${BUILD_CMD[*]}"
fi
echo ""

if [ "$VALIDATE_ONLY" = true ]; then
    if "${VALIDATE_CMD[@]}"; then
        rm -f /tmp/validation.prg
        echo "✅ Code validation passed!"
        echo ""
        echo "🎉 Validation complete! Code is ready for building."
    else
        echo "❌ Code validation failed!"
        exit 1
    fi
else
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