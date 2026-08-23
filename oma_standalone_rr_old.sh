#!/bin/bash
## oma_rr_old.sh
# 

#SBATCH --job-name=oma_rr_old               # Job name    (default: sbatch)
#SBATCH --output=error_out/oma_rr_old-%j.out          # Output file (default: slurm-%j.out)
#SBATCH --error=error_out/oma_rr_old-%j.err           # Error file  (default: slurm-%j.out)
#SBATCH --cpus-per-task=8             # Number of CPUs per task
#SBATCH --mem-per-cpu=16GB             # Memory per CPU (in MB)
#SBATCH --time=24:00:00               # Wall clock time limit (H:M:S)
# Inform the user
echo "All in one with the original Kostya(not plus) and NV2 to compare"

# load module and print information
module load OmaStandalone # load OMA (standalone version)
module list                     # list the loaded modules
lscpu | grep "Model name"       # CPU Architecture
date                            # Time of the submitted job


# run OMA part 2
cd /lisc/data/scratch/molevo/peyroche/OMA/rerun_old/
OMA -n 8

# Inform the user with time
echo " Process finished at `date`"
