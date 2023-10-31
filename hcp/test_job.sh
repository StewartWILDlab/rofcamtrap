#!/bin/bash
#SBATCH --account=rrg-fstewart
#SBATCH --gpus-per-node=1         # Number of GPU(s) per node
#SBATCH --cpus-per-node=2         # CPU cores/threads
#SBATCH --mem=8GB                 # memory per node
#SBATCH --time=00:30:00

module load apptainer

cd /home/vlucet/projects/rrg-fstewart/vlucet/rofcamtrap

apptainer exec --nv -C -B "$(pwd):/workspace/rofcamtrap" -B "/home/vlucet/projects/rrg-fstewart/vlucet:/workspace/project/" rofcamtrap.sif /workspace/rofcamtrap/scripts/bash/classify_species.sh
