#!/bin/bash

# Garmin Watch Face Build Script
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
            echo "Garmin Watch Face Build Script"
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

echo "=== Garmin Analog Watch Face Build ==="
if [ "$VALIDATE_ONLY" = true ]; then
    echo "🔍 Code validation mode"
else
    echo "🔨 Building for Forerunner 970..."
fi
echo ""

# Set up environment
export CIQ_HOME=/app/connectiq-sdk
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$CIQ_HOME/bin

# Debug: Show environment
echo "🔧 Environment check:"
echo "CIQ_HOME: $CIQ_HOME"
echo "JAVA_HOME: $JAVA_HOME"
echo "PATH: $PATH"
echo ""

# Check if MonkeyC compiler exists and is executable
if [ ! -f "$CIQ_HOME/bin/monkeyc" ]; then
    echo "❌ Error: MonkeyC compiler not found at $CIQ_HOME/bin/monkeyc"
    echo "Available files in $CIQ_HOME/bin/:"
    ls -la $CIQ_HOME/bin/ || echo "Directory does not exist"
    exit 1
fi

if [ ! -x "$CIQ_HOME/bin/monkeyc" ]; then
    echo "❌ Error: MonkeyC compiler is not executable"
    echo "Making it executable..."
    chmod +x $CIQ_HOME/bin/monkeyc
fi

# Test MonkeyC compiler
echo "🔍 Testing MonkeyC compiler..."
$CIQ_HOME/bin/monkeyc --help > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Error: MonkeyC compiler failed to run"
    echo "Trying to get version info..."
    $CIQ_HOME/bin/monkeyc --version || echo "Version check also failed"
    exit 1
fi

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

if [ ! -d "resources" ]; then
    echo "❌ Error: resources directory not found"
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

# Check for required files
echo "🔍 Checking project files..."
if [ ! -f "source/AnalogueApp.mc" ]; then
    echo "❌ Error: source/AnalogueApp.mc not found"
    echo "Available source files:"
    ls -la source/
    exit 1
fi

if [ ! -f "source/AnalogueView.mc" ]; then
    echo "❌ Error: source/AnalogueView.mc not found"
    echo "Available source files:"
    ls -la source/
    exit 1
fi

echo "✅ All required files found"

# Build the command as an array to avoid shell parsing issues
MONKEYC_CMD=(
    "$CIQ_HOME/bin/monkeyc"
    "--typecheck"
    "--manifest" "manifest.xml"
    "--sdk" "$CIQ_HOME"
    "--device" "fr970"
    "--warn"
)

# Add source files
for source_file in source/*.mc; do
    if [ -f "$source_file" ]; then
        MONKEYC_CMD+=("$source_file")
    fi
done

# Validate code first
echo "✅ Validating code..."
echo "Running: ${MONKEYC_CMD[*]}"
"${MONKEYC_CMD[@]}"

if [ $? -ne 0 ]; then
    echo "❌ Code validation failed!"
    exit 1
fi

echo "✅ Code validation passed!"

# Exit here if only validating
if [ "$VALIDATE_ONLY" = true ]; then
    echo ""
    echo "🎉 Validation complete! Code is ready for building."
    exit 0
fi

# Build the watch face
echo "🔨 Building watch face..."

# Build command
BUILD_CMD=(
    "$CIQ_HOME/bin/monkeyc"
    "--output" "build/analog-face.prg"
    "--manifest" "manifest.xml"
    "--sdk" "$CIQ_HOME"
    "--device" "fr970"
    "--warn"
    "--private-key" "$CIQ_HOME/bin/developer_key.der"
)

# Add source files
for source_file in source/*.mc; do
    if [ -f "$source_file" ]; then
        BUILD_CMD+=("$source_file")
    fi
done

echo "Running: ${BUILD_CMD[*]}"
"${BUILD_CMD[@]}"

if [ $? -eq 0 ]; then
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
    echo "4. On your watch: Settings > Watch Face > Select 'Tableau Analog'"
    echo ""
    echo "💡 Pro tip: You can also test in the simulator first:"
    echo "   connectiq -d fr970 build/analog-face.prg"
    
else
    echo ""
    echo "❌ Build failed!"
    echo "Check the error messages above for details"
    exit 1
fi