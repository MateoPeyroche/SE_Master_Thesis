#!/bin/bash
## oma_part2.sh
# This is the All vs All part

#SBATCH --job-name=oma_2               # Job name    (default: sbatch)
#SBATCH --output=error_out/oma_2-%j.out          # Output file (default: slurm-%j.out)
#SBATCH --error=error_out/oma_2-%j.err           # Error file  (default: slurm-%j.out)
#SBATCH --cpus-per-task=8             # Number of CPUs per task
#SBATCH --mem-per-cpu=16GB             # Memory per CPU (in MB)
#SBATCH --time=24:00:00               # Wall clock time limit (H:M:S)
# Inform the user
echo "[STEP 2]: All vs All and and finishing Part"

# load module and print information
module load OmaStandalone # load OMA (standalone version)
module list                     # list the loaded modules
lscpu | grep "Model name"       # CPU Architecture
date                            # Time of the submitted job


# run OMA part 2
cd /lisc/data/scratch/molevo/peyroche/OMA/
OMA -n 8

# Inform the user with time
echo "[STEP 2]: Process finished at `date`"
