FROM dorowu/ubuntu-desktop-lxde-vnc:focal

WORKDIR /workspace/analog-face

RUN apt-get install -y unzip

COPY . .
RUN chmod +x setup.sh build.sh