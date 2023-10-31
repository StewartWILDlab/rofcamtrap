#!/bin/bash
#SBATCH --account=rrg-fstewart
#SBATCH --gpus-per-node=1         # Number of GPU(s) per node
#SBATCH --cpus-per-task=1         # CPU cores/threads
#SBATCH --mem=4GB               # memory per node
#SBATCH --time=0-03:00

module load apptainer

apptainer run --nv -c rofcamtrap.sif
