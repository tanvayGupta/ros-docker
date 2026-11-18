FROM osrf/ros:humble-desktop-full

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV QT_X11_NO_MITSHM=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    libglvnd0 libgl1 libglx0 libegl1 libgles2 \
    mesa-utils x11-apps \
    ros-humble-turtlesim \
    ros-humble-gazebo-ros-pkgs \
    ros-humble-ros-gz \
    python3-colcon-common-extensions \
    git nano \
 && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc

WORKDIR /root/ros2_ws
CMD ["bash"]
