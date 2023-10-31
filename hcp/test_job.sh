#!/bin/bash
#SBATCH --account=rrg-fstewart
#SBATCH --gpus-per-node=1         # Number of GPU(s) per node
#SBATCH --cpus-per-task=1         # CPU cores/threads
#SBATCH --mem=4GB               # memory per node
#SBATCH --time=00:05:00

module load apptainer

cd /home/vlucet/projects/rrg-fstewart/vlucet/rofcamtrap

apptainer run --nv -C -B "$(pwd):/workspace/rofcamtrap" -B \
  "/home/vlucet/projects/rrg-fstewart/vlucet:/workspace/project/" rofcamtrap.sif cd /workspace/rofcamtrap && ./scripts/bash/classify_species.sh
