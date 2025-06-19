FROM dorowu/ubuntu-desktop-lxde-vnc

WORKDIR /workspace/analog-face

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    unzip \
    curl \
    bash \
    ca-certificates \
    libusb-1.0-0 \
    libsecret-1-0 \
    libwebkit2gtk-4.0-37 \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

COPY . .
RUN chmod +x setup.sh build.sh