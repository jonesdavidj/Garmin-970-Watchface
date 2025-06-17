#!/bin/bash
set -e

echo "📦 Extracting Garmin SDK from /mnt/hs_dev/GarminSDK.tgz..."

cd /workspace/analog-face

# Only extract if not already unpacked
if [ ! -d "connectiq-sdk" ]; then
    if [ ! -f /mnt/hs_dev/GarminSDK.tgz ]; then
        echo "❌ GarminSDK.tgz not found in /mnt/hs_dev"
        exit 1
    fi

    tar --no-same-owner -xzf /mnt/hs_dev/GarminSDK.tgz

    # Flatten the SDK structure
    mkdir -p connectiq-sdk
    mv ConnectIQ/Sdks/* connectiq-sdk/
else
    echo "✅ SDK already extracted."
fi

# Detect the extracted SDK version directory
CIQ_HOME=$(find /workspace/analog-face/connectiq-sdk -type d -name "connectiq-sdk-lin-*" | head -n 1)

if [ -z "$CIQ_HOME" ]; then
    echo "❌ SDK folder not found under connectiq-sdk/"
    exit 1
fi

# Set environment
export CIQ_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$PATH:$CIQ_HOME/bin

# Make tools executable
chmod +x $CIQ_HOME/bin/*

echo ""
echo "🔧 SDK Info:"
monkeyc --version || { echo "❌ MonkeyC compiler not working"; exit 1; }

echo ""
echo "📋 Checking available devices in SDK:"
connectiq devices list || { echo "❌ Failed to list devices"; exit 1; }

echo ""
echo "🔍 Verifying fr970 is available:"
if connectiq devices list | grep -q fr970; then
    echo "✅ fr970 device found in SDK."
else
    echo "❌ fr970 not registered in SDK!"
    echo "ℹ️  You may need to run:  connectiq devices install fr970"
    exit 1
fi

echo ""
echo "🔨 Running build.sh..."
chmod +x build.sh
monkeyc --version
connectiq devices list
