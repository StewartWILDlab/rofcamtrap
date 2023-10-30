
# Dockerfile for running the programming environemment

# Build frome cuda
FROM nvidia/cuda:12.2.0-base-ubuntu22.04

# Setup workspace
WORKDIR /workspace

# Install basic system dependencies
RUN apt-get update && apt-get install -y wget git build-essential

# Install cv2 dependencies
RUN apt-get update && apt-get install -y ffmpeg libsm6 libxext6 curl

# Install Python
RUN apt-get update && apt-get install -y python3.10

# Start with miniforge/mambaforge
RUN wget -O Miniforge3.sh \
  "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
RUN bash Miniforge3.sh -b -p "/workspace/conda"

# Download MD model
RUN mkdir models
RUN wget -O models/md_v5a.0.0.pt \
  https://github.com/agentmorris/MegaDetector/releases/download/v5.0/md_v5a.0.0.pt

# Install MD dependencies
RUN mkdir git && cd git \
  && git clone https://github.com/agentmorris/MegaDetector \
  && git clone https://github.com/ecologize/yolov5/

# Create MD env
RUN cd /workspace/git/MegaDetector \
  && . "/workspace/conda/etc/profile.d/conda.sh" \
  && . "/workspace/conda/etc/profile.d/mamba.sh" \
  && mamba env create --file envs/environment-detector.yml
  # && mamba activate cameratraps-detector

# Install project dependencies
RUN git clone https://github.com/StewartWILDlab/mdtools
RUN curl -sSL https://install.python-poetry.org | python3.10 -

# Install poetry env
RUN cd mdtools \
  && $HOME/.local/bin/poetry install

# Set up env at container startup
RUN echo ". /workspace/conda/etc/profile.d/conda.sh \
  && . /workspace/conda/etc/profile.d/mamba.sh \
  && PATH="$PATH:$HOME/.local/bin"" >> ~/.bashrc

ENTRYPOINT ["/bin/bash"]
