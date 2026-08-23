#!/bin/bash
## oma_part1.sh
# This is the database conversion part

#SBATCH --job-name=oma_test               # Job name    (default: sbatch)
#SBATCH --output=error_out/oma_test-%j.out          # Output file (default: slurm-%j.out)
#SBATCH --error=error_out/oma_test-%j.err           # Error file  (default: slurm-%j.out)
#SBATCH --cpus-per-task=1             # Number of CPUs per task
#SBATCH --mem-per-cpu=1GB             # Memory per CPU (in MB)
#SBATCH --time=00:30:00               # Wall clock time limit (H:M:S)
# Inform the user
echo "[STEP 1]: Database Conversion Part"

# load module and print information
module load OmaStandalone # load OMA (standalone version)
module list                     # list the loaded modules
lscpu | grep "Model name"       # CPU Architecture
date                            # Time of the submitted job


# run OMA part 1
cd /lisc/data/scratch/molevo/peyroche/OMA/
OMA -c

# Inform the user with time
echo "[STEP 1]: Process finished at `date`"
