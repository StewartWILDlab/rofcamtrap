#!/bin/bash

# This is for putting the models other than resnets on path
# export PYTHONPATH="$PYTHONPATH:/media/vlucet/TrailCamST/Cropped/InternImage"
# export PYTHONPATH="$PYTHONPATH:/media/vlucet/TrailCamST/Cropped/InternImage/classification/ops_dcnv3"
# export PYTHONPATH="$PYTHONPATH:/media/vlucet/TrailCamST/Cropped/metaformer"

# Necessary to make torch work properly on laptop
# export 'PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512'

# Necessary only on cluster
# Move to folder within container,
#   source the conda and mamba binaries, put bin on path
#   activate the MD environment in which we also run the classifiers
cd /workspace/rofcamtrap
source /workspace/conda/etc/profile.d/conda.sh
source /workspace/conda/etc/profile.d/mamba.sh
PATH="$PATH:$HOME/.local/bin"
mamba activate cameratraps-detector

# Run main script
python3 ./scripts/python/species_classifier/classify_species.py
