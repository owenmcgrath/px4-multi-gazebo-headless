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
    echo "  -x    Sets the number of IRIS quads"
    echo "  -p    Sets the number of planes"
    echo "  -v    Sets the number of VTOL"
    echo "  -r    Sets the number of rovers"
    echo "  -w    Set the world (default: empty)"
    echo ""
    echo "  <IP_API> is the IP to which PX4 will send MAVLink on UDP port 14540"
    echo "  <IP_QGC> is the IP to which PX4 will send MAVLink on UDP port 14550"
    echo ""
    echo "By default, MAVLink is sent to the host."
}

OPTIND=1 # Reset in case getopts has been used previously in the shell.

model=iris
count=3
instance=0
world=empty

while getopts "h?v:w:p:r:x:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  vtol=$OPTARG
        ;;
    p)  plane=$OPTARG
        ;;    
    r)  rover=$OPTARG
        ;;    
    x)  iris=$OPTARG
        ;;
    w)  world=$OPTARG
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


LAUNCH_SCRIPT=""

if [ "$iris" -gt "0" ]; then 
    LAUNCH_SCRIPT+="iris:${iris},"
fi 

if [ "$plane" -gt "0" ]; then 
    LAUNCH_SCRIPT+="plane:${plane},"
fi

if [ "$vtol" -gt "0" ]; then 
    LAUNCH_SCRIPT+="standard_vtol:${vtol},"
fi

if [ "$rover" -gt "0" ]; then 
    LAUNCH_SCRIPT+="rover:${rover},"
fi


echo Tools/gazebo_sitl_multiple_run.sh -w ${world} -s ${LAUNCH_SCRIPT}
source ${WORKSPACE_DIR}/edit_rcS.bash ${IP_API} ${IP_QGC} &&
cd ${FIRMWARE_DIR} &&
Tools/gazebo_sitl_multiple_run.sh -w ${world} -s ${LAUNCH_SCRIPT}