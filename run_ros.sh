#!/usr/bin/env bash
# let containers draw on the desktop's display
xhost +local: >/dev/null

mkdir -p "$HOME/ros2_ws/src"

docker run -it --rm \
  --gpus all \
  --net=host --ipc=host \
  -e DISPLAY="$DISPLAY" \
  -e QT_X11_NO_MITSHM=1 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$HOME/ros2_ws":/root/ros2_ws \
  --name ros2 \
  tanvaygupta/ros2-humble-gpu:latest "$@"
