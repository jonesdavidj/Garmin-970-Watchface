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
    libwebkit2gtk-4.0-37 \
    libsecret-1-0 \
    libusb-1.0-0 \
    libgtk-3-0 \
    libxkbcommon0 \
    libnss3 \
    libglib2.0-0 \
    libxcb1 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libpangocairo-1.0-0 \
    libcairo2 \
    libjpeg62 \
    libopenjp2-7 \
    libwebp7 \
    libenchant-2-2 \
    libnotify4 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Symlinks to satisfy older Garmin SDK dependencies
RUN ln -s /usr/lib/x86_64-linux-gnu/libwebp.so.7 /usr/lib/x86_64-linux-gnu/libwebp.so.6 && \
    ln -s /usr/lib/x86_64-linux-gnu/libenchant-2.so.2 /usr/lib/x86_64-linux-gnu/libenchant.so.1

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Create working directory
WORKDIR /workspace/analog-face

# Download and install Connect IQ SDK (cached layer)
RUN wget https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-lin-8.1.1-2025-03-27-66dae750f.zip -O connectiq-sdk.zip && \
    unzip connectiq-sdk.zip && \
    # The extracted folder should be named exactly as the zip file (minus .zip)
    mv connectiq-sdk-lin-8.1.1-2025-03-27-66dae750f connectiq-sdk && \
    chmod +x connectiq-sdk/bin/* && \
    rm connectiq-sdk.zip

# Copy the entire project
COPY . /workspace/analog-face

# Set Connect IQ SDK environment variables
ENV CIQ_HOME=/workspace/analog-face/connectiq-sdk
ENV PATH=$PATH:$CIQ_HOME/bin

# Make SDK binaries executable
RUN find $CIQ_HOME/bin -type f -exec chmod +x {} \; || true

# Verify SDK structure
RUN echo "SDK structure:" && \
    ls -la $CIQ_HOME/ && \
    echo "SDK bin contents:" && \
    ls -la $CIQ_HOME/bin/ && \
    echo "Checking for required files:" && \
    test -f $CIQ_HOME/bin/monkeyc && echo "✅ monkeyc found" || echo "❌ monkeyc missing" && \
    test -f $CIQ_HOME/bin/api.db && echo "✅ api.db found" || echo "❌ api.db missing" && \
    test -f $CIQ_HOME/bin/api.mir && echo "✅ api.mir found" || echo "❌ api.mir missing" && \
    test -f $CIQ_HOME/bin/devices.xml && echo "✅ devices.xml found" || echo "❌ devices.xml missing"

# Create a development key for local builds
RUN mkdir -p $CIQ_HOME/keys && \
    cd $CIQ_HOME/keys && \
    openssl genrsa -out developer_key.pem 4096 && \
    openssl rsa -in developer_key.pem -outform DER -out developer_key.der && \
    # Copy the key to bin directory for easier access
    cp developer_key.der $CIQ_HOME/bin/

# Make build script executable
RUN chmod +x build.sh

# Create useful aliases and environment setup
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'export PS1="[Garmin Dev] \w $ "' >> /root/.bashrc && \
    echo 'export CIQ_HOME=/workspace/analog-face/connectiq-sdk' >> /root/.bashrc && \
    echo 'export PATH=$PATH:$CIQ_HOME/bin' >> /root/.bashrc

# Wrapper script for headless simulator usage
RUN echo '#!/bin/bash\nxvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" "$CIQ_HOME/bin/connectiq" "$@"' > /usr/local/bin/connectiq-headless && \
    chmod +x /usr/local/bin/connectiq-headless

# Test the compiler
RUN echo "Testing MonkeyC compiler..." && \
    $CIQ_HOME/bin/monkeyc --version || echo "Compiler test failed - this may be normal if no display is available"

# Keep container running
CMD ["tail", "-f", "/dev/null"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD test -f $CIQ_HOME/bin/monkeyc && test -f $CIQ_HOME/bin/api.db || exit 1