FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    openjdk-11-jdk \
    python3 \
    python3-pip \
    git \
    curl \
    build-essential \
    vim \
    nano \
    htop \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Create working directory
WORKDIR /app

# Download and install Connect IQ SDK Manager
RUN wget https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-manager-linux.zip -O sdk-manager.zip && \
    unzip sdk-manager.zip && \
    rm sdk-manager.zip && \
    chmod +x connectiq-sdk-manager-linux

# Install the latest SDK using SDK Manager
RUN ./connectiq-sdk-manager-linux --yes && \
    rm connectiq-sdk-manager-linux

# Set Connect IQ SDK environment variables
ENV CIQ_HOME=/root/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin
ENV PATH=$PATH:$CIQ_HOME/bin

# Create a development key for local builds
RUN mkdir -p $CIQ_HOME/bin && \
    cd $CIQ_HOME/bin && \
    openssl genrsa -out developer_key.pem 4096 && \
    openssl rsa -in developer_key.pem -outform DER -out developer_key.der

# Create workspace directory
RUN mkdir -p /workspace

# Set working directory to workspace
WORKDIR /workspace

# Create useful aliases and environment setup
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias build="monkeyc --output build/analog-face.prg --manifest manifest.xml --sdk \$CIQ_HOME --device fr970 --warn --private-key \$CIQ_HOME/bin/developer_key.der source/*.mc"' >> /root/.bashrc && \
    echo 'alias validate="monkeyc --typecheck --manifest manifest.xml --sdk \$CIQ_HOME --device fr970 source/*.mc"' >> /root/.bashrc && \
    echo 'export PS1="[Garmin Dev] \w $ "' >> /root/.bashrc

# Create build script for easy use
RUN echo '#!/bin/bash\n\
echo "=== Garmin Classic Watch Face Build ==="\n\
cd /workspace\n\
\n\
# Check if project files exist\n\
if [ ! -f "manifest.xml" ]; then\n\
    echo "Error: manifest.xml not found in /workspace"\n\
    echo "Make sure your GitHub repo is mounted to /workspace"\n\
    exit 1\n\
fi\n\
\n\
# Create build directory\n\
mkdir -p build\n\
\n\
echo "Building watch face..."\n\
monkeyc \\\n\
  --output build/analog-face.prg \\\n\
  --manifest manifest.xml \\\n\
  --sdk $CIQ_HOME \\\n\
  --device fr970 \\\n\
  --warn \\\n\
  --private-key $CIQ_HOME/bin/developer_key.der \\\n\
  source/*.mc\n\
\n\
if [ $? -eq 0 ]; then\n\
    echo "✅ Build successful!"\n\
    echo "Output: build/analog-face.prg"\n\
    ls -la build/\n\
    echo ""\n\
    echo "To install on your Forerunner 970:"\n\
    echo "1. Copy build/analog-face.prg to GARMIN/APPS folder"\n\
    echo "2. Select the watch face in your watch settings"\n\
else\n\
    echo "❌ Build failed!"\n\
    exit 1\n\
fi\n\
' > /usr/local/bin/build-watchface && chmod +x /usr/local/bin/build-watchface

# Create validation script
RUN echo '#!/bin/bash\n\
echo "=== Validating Garmin Watch Face Code ==="\n\
cd /workspace\n\
\n\
monkeyc \\\n\
  --typecheck \\\n\
  --manifest manifest.xml \\\n\
  --sdk $CIQ_HOME \\\n\
  --device fr970 \\\n\
  source/*.mc\n\
\n\
if [ $? -eq 0 ]; then\n\
    echo "✅ Code validation successful!"\n\
else\n\
    echo "❌ Code validation failed!"\n\
    exit 1\n\
fi\n\
' > /usr/local/bin/validate-code && chmod +x /usr/local/bin/validate-code

# Keep container running
CMD ["tail", "-f", "/dev/null"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD java -version && monkeyc --version || exit 1