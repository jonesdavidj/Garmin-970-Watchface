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
WORKDIR /workspace/analog-face
COPY . /workspace/analog-face

# Create useful aliases and environment setup
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias build="monkeyc --output build/analog-face.prg --manifest manifest.xml --device fr970 --device-path Devices/fr970 --fonts Fonts --warn --private-key \$CIQ_HOME/bin/developer_key.der source/*.mc"' >> /root/.bashrc && \
    echo 'alias validate="monkeyc --typecheck --manifest manifest.xml --device fr970 --device-path Devices/fr970 source/*.mc"' >> /root/.bashrc && \
    echo 'export PS1="[Garmin Dev] \w $ "' >> /root/.bashrc

# Wrapper script for headless simulator usage
RUN echo '#!/bin/bash\nxvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" "$CIQ_HOME/bin/connectiq" "$@"' > /usr/local/bin/connectiq-headless && \
    chmod +x /usr/local/bin/connectiq-headless

RUN chmod +x /workspace/analog-face/connectiq-headless.sh
RUN chmod +x build.sh

# Keep container running
CMD ["tail", "-f", "/dev/null"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD java -version && monkeyc --version || exit 1
