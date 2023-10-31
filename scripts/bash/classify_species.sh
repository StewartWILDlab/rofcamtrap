#!/bin/bash

# export PYTHONPATH="$PYTHONPATH:/media/vlucet/TrailCamST/Cropped/InternImage"
# export PYTHONPATH="$PYTHONPATH:/media/vlucet/TrailCamST/Cropped/InternImage/classification/ops_dcnv3"
# export PYTHONPATH="$PYTHONPATH:/media/vlucet/TrailCamST/Cropped/metaformer"

export 'PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512'

python3 ./scripts/python/species_classifier/classify_species.py
# python3 ./scripts/classsify_lightning.py
