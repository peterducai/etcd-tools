#!/bin/bash

STAMP=$(date +%Y-%m-%d_%H-%M-%S)

# run iostat 20 times with delay of 2 seconds
iostat -dmx 2 20 > iostat.log