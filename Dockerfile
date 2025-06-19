FROM dorowu/ubuntu-desktop-lxde-vnc:focal

WORKDIR /workspace/analog-face

RUN apt-get update || (cat /etc/apt/sources.list && cat /var/lib/apt/lists/*Release* && exit 1)

# Rebuild the apt sources to ensure compatibility
RUN echo "deb http://archive.ubuntu.com/ubuntu focal main universe restricted multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu focal-updates main universe restricted multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu focal-security main universe restricted multiverse" >> /etc/apt/sources.list && \
    apt-get clean && \
    apt-get update && \
    apt-get install -y bash


RUN apt install -y openjdk-11-jdk
RUN apt install -y unzip
RUN apt install -y curl
RUN apt install -y ca-certificates
RUN apt install -y libusb-1.0-0
RUN apt install -y libsecret-1-0
RUN apt install -y libgtk-3-0
RUN apt install -y libnss3
RUN apt install -y libxss1
RUN apt install -y libasound2
RUN apt install -y libwebkit2gtk-4.0-37
RUN rm -rf /var/lib/apt/lists/*

COPY . .
RUN chmod +x setup.sh build.sh