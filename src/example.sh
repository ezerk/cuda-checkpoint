#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

set -v

# run the counter application
./counter &

#get the PID of counter
PID=$!
DEMO_DIR=demo
# wait for counter to bind to the UDP socket
sleep 1

#send a packet
echo hello | nc -u 127.0.0.1 10000 -w 1

# confirm that counter is using the GPU
nvidia-smi --query --display=PIDS | grep $PID

# suspend CUDA
cuda-checkpoint --toggle --pid $PID

# confirm that counter is no longer using the GPU
nvidia-smi --query --display=PIDS | grep $PID

# create the directory which will hold the checkpoint image
mkdir -p $DEMO_DIR

# checkpoint counter
sudo criu dump -vvvv -o dump.log --display-stats --shell-job --images-dir $DEMO_DIR --tree $PID

# confirm that counter is no longer running
ps --pid $PID

# restore counter
sudo criu restore -vvvv -o restore.log --shell-job --restore-detached --images-dir $DEMO_DIR

# resume CUDA
cuda-checkpoint --toggle --pid $PID

# wait for counter to bind to the UDP socket
sleep 2

# send another packet
echo hello | nc -u 127.0.0.1 10000 -w 1

kill $PID
