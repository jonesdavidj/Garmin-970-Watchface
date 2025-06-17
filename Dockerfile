FROM ubuntu:22.04

# Set working directory
WORKDIR /workspace/analog-face

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    unzip \
    bash \
    curl \
    ca-certificates \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# Copy project into container
COPY . .

# Extract Garmin SDK
RUN unzip Garmin.zip -d connectiq-sdk

# Make SDK tools executable
RUN chmod +x connectiq-sdk/bin/*

# Set environment variables
ENV CIQ_HOME=/workspace/analog-face/connectiq-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$CIQ_HOME/bin

# Test SDK installation
RUN monkeyc --version || echo "❌ MonkeyC not working"
RUN connectiq devices list || echo "❌ Could not list devices"

# Default shell
CMD ["/bin/bash"]