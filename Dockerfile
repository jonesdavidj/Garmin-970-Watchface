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
    libwebkit2gtk-4.1-0 \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Create working directory
WORKDIR /app

# Lets make sure first that we can unzip the Connect IQ SDK
RUN apt-get update && apt-get install -y unzip wget

# Download and install Connect IQ SDK (cached layer)
RUN wget https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-lin-8.1.1-2025-03-27-66dae750f.zip -O connectiq-sdk.zip
RUN unzip connectiq-sdk.zip
RUN mkdir connectiq-sdk && \
    mv bin doc resources samples share connectiq-sdk/ && \
    chmod +x connectiq-sdk/bin/*
RUN echo "SDK unzipped and organized."

# Set Connect IQ SDK environment variables
ENV CIQ_HOME=/app/connectiq-sdk
ENV PATH=$PATH:$CIQ_HOME/bin

#RUN cd ${CIQ_HOME}/bin && \
#    ./connectiq --download-devices
#RUN echo "Devices downloaded for sdk"

# Create a development key for local builds
RUN cd $CIQ_HOME/bin && \
    openssl genrsa -out developer_key.pem 4096 && \
    openssl rsa -in developer_key.pem -outform DER -out developer_key.der

# Create workspace directory
RUN mkdir -p /workspace

# Set working directory to workspace
WORKDIR /workspace/analog-face
COPY . /workspace/analog-face

# Create useful aliases and environment setup
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias build="monkeyc --output build/analog-face.prg --manifest manifest.xml --sdk \$CIQ_HOME --device fr970 --warn --private-key \$CIQ_HOME/bin/developer_key.der source/*.mc"' >> /root/.bashrc && \
    echo 'alias validate="monkeyc --typecheck --manifest manifest.xml --sdk \$CIQ_HOME --device fr970 source/*.mc"' >> /root/.bashrc && \
    echo 'export PS1="[Garmin Dev] \w $ "' >> /root/.bashrc

# Keep container running
CMD ["tail", "-f", "/dev/null"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD java -version && monkeyc --version || exit 1
