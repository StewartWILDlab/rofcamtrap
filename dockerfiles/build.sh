#!/usr/bin/bash

docker build -t rofcamtrap dockerfiles
docker save rofcamtrap -o rofcamtrap.tar
# docker image rm rofcamtrap
apptainer build --fakeroot rofcamtrap.sif docker-archive://rofcamtrap.tar
rm rofcamtrap.tar
