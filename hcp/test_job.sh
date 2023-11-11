#!/bin/bash
#SBATCH --mail-user=valentin.lucet@gmail.com
#SBATCH --mail-type=END,FAIL
#SBATCH --account=rrg-fstewart
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1         # Number of GPU(s) per node
#SBATCH --cpus-per-task=1         # CPU cores/threads
#SBATCH --mem=8GB                 # memory per node
#SBATCH --time=35:00:00
#SBATCH --output slurm-%j.log

# https://unix.stackexchange.com/questions/285690/slurm-custom-standard-output-name
ln -f slurm-${SLURM_JOB_ID}.log output.log

# Load the apptainer module, latest is fine
module load apptainer

# Move into the rofcamtrap folder
cd /home/vlucet/projects/rrg-fstewart/vlucet/rofcamtrap

# Run apptainer, exec the classify species bash script
#   --nv makes nvidia cuda work
#   -C contains the filesystem, used for simplicity
#   -B allows to bind volumes, similar to -v for docker
apptainer exec --nv -C -B "$(pwd):/workspace/rofcamtrap" \
  -B "/home/vlucet/projects/rrg-fstewart/vlucet:/workspace/project/" \
  rofcamtrap.sif /workspace/rofcamtrap/scripts/bash/classify_species.sh

# https://unix.stackexchange.com/questions/285690/slurm-custom-standard-output-name
rm slurm-${SLURM_JOB_ID}.log
