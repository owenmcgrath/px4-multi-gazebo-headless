FROM px4io/px4-dev-simulation-bionic

ENV WORKSPACE_DIR /root
ENV FIRMWARE_DIR ${WORKSPACE_DIR}/Firmware
ENV SITL_RTSP_PROXY ${WORKSPACE_DIR}/sitl_rtsp_proxy

ENV DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
ENV DISPLAY :99
ENV LANG C.UTF-8

RUN apt-get update --fix-missing -y && apt-get upgrade -y
RUN apt-get install -y libgstrtspserver-1.0-dev gstreamer1.0-rtsp xvfb
RUN git clone -b v1.12.3 https://github.com/PX4/PX4-Autopilot.git ${FIRMWARE_DIR}
RUN git -C ${FIRMWARE_DIR} submodule update --init --recursive

COPY edit_rcS.bash ${WORKSPACE_DIR}
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

RUN ["/bin/bash", "-c", " \
    cd ${FIRMWARE_DIR} && \
    DONT_RUN=1 HEADLESS=1 make px4_sitl_default gazebo && \
    DONT_RUN=1 HEADLESS=1 make px4_sitl_default gazebo \
"]

COPY gazebo_sitl_multiple_run.sh ${FIRMWARE_DIR}/Tools/gazebo_sitl_multiple_run.sh
COPY sitl_rtsp_proxy ${SITL_RTSP_PROXY}
RUN cmake -B${SITL_RTSP_PROXY}/build -H${SITL_RTSP_PROXY}
RUN cmake --build ${SITL_RTSP_PROXY}/build

ENTRYPOINT ["/root/entrypoint.sh"]
