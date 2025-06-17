#!/bin/bash
set -e

echo "📦 Extracting SDK from /mnt/hs_dev/GarminSDK.tgz..."

cd /workspace/analog-face

# Only extract if it hasn't already been unpacked
if [ ! -d "connectiq-sdk" ]; then
    if [ ! -f /mnt/hs_dev/GarminSDK.tgz ]; then
        echo "❌ GarminSDK.tgz not found in /mnt/hs_dev"
        exit 1
    fi
    tar --no-same-owner -xzf /mnt/hs_dev/GarminSDK.tgz
    mkdir -p connectiq-sdk
    mv ConnectIQ/Sdks/* connectiq-sdk/
else
    echo "✅ SDK already extracted."
fi

# Set environment variables
export CIQ_HOME=/workspace/analog-face/connectiq-sdk
export PATH=$PATH:$CIQ_HOME/bin
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Make sure tools are executable
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

