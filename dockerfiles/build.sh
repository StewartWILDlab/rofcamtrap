#!/usr/bin/bash

docker build -t rofcamtrap rofcamtrap/dockerfiles
docker save rofcamtrap -o rofcamtrap/rofcamtrap.tar
# docker image rm rofcamtrap
apptainer build --fakeroot rofcamtrap/rofcamtrap.sif docker-archive://rofcamtrap.tar
# rm rofcamtrap/rofcamtrap.tar
