#!/bin/bash

function show_help {
    echo ""
    echo "Usage: ${0} [-h | -c IRIS_COUNT | -p PLANE_COUNT | -v VTOL_COUNT | -w WORLD] [IP_API | IP_QGC IP_API]"
    echo ""
    echo "Run a headless px4-gazebo simulation in a docker container. The"
    echo "available vehicles and worlds are the ones available in PX4"
    echo "(i.e. when running e.g. \`make px4_sitl gazebo_iris__baylands\`)"
    echo ""
    echo "  -h    Show this help"
    echo "  -m    Sets the model of the vehicle to launch"
    echo "  -n    Sets the mnumber of vehicles to launch"
    echo "  -i    Sets the px4 start instance"
    echo ""
    echo "  <IP_API> is the IP to which PX4 will send MAVLink on UDP port 14540"
    echo "  <IP_QGC> is the IP to which PX4 will send MAVLink on UDP port 14550"
    echo ""
    echo "By default, MAVLink is sent to the host."
}

OPTIND=1 # Reset in case getopts has been used previously in the shell.

model=iris
count=3

while getopts "h?w:m:i:n:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    m)  model=$OPTARG
        ;;
    n)  count=$OPTARG
        ;;
    i)  instance=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

# All the leftover arguments are supposed to be IPs
for arg in "$@"
do
    if ! [[ ${arg} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: invalid IP: ${arg}!"
        echo ""
        show_help
        exit 1
    fi
done

if [ "$#" -eq 1 ]; then
    IP_QGC="$1"
elif [ "$#" -eq 2 ]; then
    IP_API="$1"
    IP_QGC="$2"
elif [ "$#" -gt 2 ]; then
    show_help
    exit 1;
fi

Xvfb :99 -screen 0 1600x1200x24+32 &
${SITL_RTSP_PROXY}/build/sitl_rtsp_proxy &

echo Tools/gazebo_sitl_multiple_run.sh -i ${instance} -m ${model} -n ${count}
source ${WORKSPACE_DIR}/edit_rcS.bash ${IP_API} ${IP_QGC} &&
cd ${FIRMWARE_DIR} &&
Tools/gazebo_sitl_multiple_run.sh -i ${instance} -m ${model} -n ${count}