FROM dorowu/ubuntu-desktop-lxde-vnc:focal

WORKDIR /workspace/analog-face


COPY . .
RUN chmod +x setup.sh build.sh