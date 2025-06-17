FROM ubuntu:22.04

WORKDIR /workspace/analog-face

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    unzip \
    curl \
    bash \
    ca-certificates \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . .

RUN echo "📦 Extracting Garmin SDK..." && \
    tar --no-same-owner -xzf /external/hs_dev/GarminSDK.tgz && \
    if [ -d "ConnectIQ" ]; then \
      mv ConnectIQ connectiq-sdk && echo "✅ SDK moved to connectiq-sdk/"; \
    else \
      echo "❌ ConnectIQ directory not found after extract"; \
      exit 1; \
    fi


# Make tools executable
RUN chmod +x connectiq-sdk/bin/*

# Set environment
ENV CIQ_HOME=/workspace/analog-face/connectiq-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$CIQ_HOME/bin

# Confirm install
RUN monkeyc --version || echo "MonkeyC missing"
RUN connectiq devices list || echo "Device list failed"

CMD ["/bin/bash"]
