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
    libsecret-1-0
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . .
RUN chmod +x setup.sh build.sh

# Set environment
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$CIQ_HOME/bin

CMD ["tail", "-f", "/dev/null"]