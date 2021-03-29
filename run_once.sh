#!/bin/bash
# This script will launch the simulator/ROS.
# The optional parameter may tell us to use default settings.

ARG=${1:-empty}
DEF="default"

# grab the epoch datetime to use as a uniform filename in the default case.
FNAME=`date +%s`
echo "FNAME is: ${FNAME}"

# make sure we have sourced the right ros workspace.
source sim_ws/devel/setup.bash

if [ "$ARG" = "$DEF" ]; then
    echo "Using default KF settings."
    # make sure the KF uses its default parameters.
    python3 functions/reset_for_solo_run.py $FNAME
fi

# Launch the simulator.
# This assumes you are using the SWC sim version 6.0,
# and that its file has been unzipped and placed in the '~/Simulators' directory.
# You may also need to ensure the launch file is made executable.
# Lastly, when the sim opens, you need to set the "repo root".
# For me, this is "/home/kevinrobb/capstone-kf-ml".
./../Simulators/SCR_SWC_20_SIM_6.0_LINUX/SCRSWC20.x86_64 &

# Start my ROS code
roslaunch capstone kf.launch &
# Wait for the simulator to finish, then kill ROS.
wait %1
#kill -9 $ROS_PID
killall -9 roscore
killall -9 rosmaster

# in the default case, go ahead and plot the data
if [ "$ARG" = "$DEF" ]; then
    echo "Creating plot of KF data."
    Rscript --vanilla functions/plot_cl_track.R $FNAME
    #need to pass the filename as a param, which is annoying to get here
fi

# the script should now kill itself so we can move on
kill -9 $$