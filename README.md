# ros-docker

A GPU-enabled **ROS 2 Humble** Docker setup for running GUI tools (RViz2, Gazebo, turtlesim) on a remote cloud machine. It was built for [Vast.ai](https://vast.ai) GPU instances using the **Linux Desktop (VM)** template, but it works on any Linux host with an NVIDIA GPU and a running desktop session.

Instead of spending ~15 minutes installing ROS on every new instance, I built the image once, pushed it to Docker Hub, and on each new machine you only clone this repo and run one script.

## What's included

The image is based on `osrf/ros:humble-desktop-full` (Ubuntu 22.04) and adds:

- ROS 2 Humble desktop-full (RViz2, rqt, demos)
- turtlesim
- Gazebo Classic via `ros-humble-gazebo-ros-pkgs`
- Gazebo (Fortress) via `ros-humble-ros-gz`
- `colcon`, `git`, `nano`
- OpenGL libraries (`libglvnd`, `libgl1`, `libegl1`) and `mesa-utils` so the NVIDIA GPU can render inside the container

## Repository layout

```
ros-docker/
├── Dockerfile      # image definition
├── ros_run.sh      # starts the container with GPU + display access
└── README.md
```

## Requirements

On the **host machine**:

- An NVIDIA GPU with a working driver (`nvidia-smi` must work)
- Docker
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (so `docker run --gpus all` works)
- A running graphical desktop session (the script uses `DISPLAY` and the X11 socket)
- `xhost` (`sudo apt install -y x11-xserver-utils` if missing)

On Vast.ai, the **Linux Desktop (VM)** template already provides all of this. Open the desktop through the Instance Portal (Selkies or Guacamole) and use a terminal inside it.

## Quick start

Run these in a terminal **inside the desktop session**, not over plain SSH:

```bash
git clone https://github.com/tanvayGupta/ros-docker
cd ros-docker
chmod +x ros_run.sh
./ros_run.sh
```

The first run pulls `tanvaygupta/ros2-humble-gpu:latest` from Docker Hub. After that you are inside the container with ROS 2 sourced and your workspace at `/root/ros2_ws`.

If you get `permission denied` from Docker, either prefix the script with `sudo` or add yourself to the docker group:

```bash
sudo usermod -aG docker $USER && newgrp docker
```

## Verify the GPU and display

Inside the container:

```bash
nvidia-smi                          # should list your GPU
glxinfo -B | grep -i renderer       # should mention NVIDIA, not llvmpipe
ros2 run turtlesim turtlesim_node   # a window should appear on your desktop
```

Then try `rviz2`, `gazebo` (Gazebo Classic) or `ign gazebo` (Fortress).

## Working with the container

### Open a second terminal in the same container

The script names the container `ros2`. From a **new host terminal**:

```bash
docker exec -it ros2 bash
source /root/ros2_ws/install/setup.bash   # if you have built your workspace
```

### Your workspace

`~/ros2_ws` on the host is mounted at `/root/ros2_ws` in the container, so source code and build output survive container restarts. Typical flow:

```bash
cd ~/ros2_ws
colcon build --symlink-install
source install/setup.bash
ros2 run <package> <node>
```

Every new terminal needs `source install/setup.bash` before running your packages.

> **Cloud instances are temporary.** If you destroy the machine, `~/ros2_ws` disappears with it. Keep your source code in a git repo and push before you destroy the instance.

## Building the image yourself

```bash
docker build -t <dockerhub-username>/ros2-humble-gpu:latest .
docker login
docker push <dockerhub-username>/ros2-humble-gpu:latest
```

Then change the image name at the bottom of `ros_run.sh` to match. Docker image names and Docker Hub usernames **must be lowercase**.

Tip: use version tags (`:v1`, `:v2`) when you change the Dockerfile so you can roll back.

## Troubleshooting

| Problem | Fix |
|---|---|
| `Failed to initialize NVML: Driver/library version mismatch` | The host's NVIDIA driver and libraries are out of sync, usually after `apt upgrade`. Reboot the machine. Avoid `apt upgrade` on GPU hosts. |
| `Unable to create GLX context` / RViz or Gazebo crashes | Usually a GPU driver problem on the host. Check `nvidia-smi` on the host first, and confirm `DISPLAY` is set (`echo $DISPLAY`, usually `:0`). |
| Windows don't appear | Re-run `xhost +local:` on the host and make sure you launched from a terminal inside the desktop session. |
| RViz or Gazebo feels slow, renderer says `llvmpipe` | Rendering is on the CPU. Check the NVIDIA Container Toolkit and `--gpus all`. |
| `Package '...' not found` | Run `source /root/ros2_ws/install/setup.bash` in that terminal. |
| `docker push` tries to contact a hostname | Your image name has uppercase letters. Use lowercase. |
| Desktop page won't load on a mobile hotspot | Some carriers block uncommon ports. Try another network or an SSH tunnel to the desktop ports. |

## Security note

`ros_run.sh` runs `xhost +local:`, which lets local processes connect to your X display. This is fine on a throwaway cloud instance, but you may want a stricter setup on a shared or personal machine.

## Credits

Built on the official [`osrf/ros`](https://hub.docker.com/r/osrf/ros) images.
