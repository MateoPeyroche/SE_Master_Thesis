#!/bin/bash
#SBATCH --job-name=sanma_signalP
#SBATCH --mem=64GB
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,END,TIME_LIMIT_50,TIME_LIMIT_80,TIME_LIMIT
#SBATCH --output=error_out/sanma_signalP_%j.log
#SBATCH --error=error_out/sanma_signalP_%j.err
#SBATCH --export=ALL

module load SignalP
module list

prots="/lisc/data/scratch/molevo/peyroche/clytia/clytia_ortho_search/data/proteomes/Sanma_proteome_1p1g.fasta"
out="/lisc/data/scratch/molevo/peyroche/sanderia/annotations/signalP/"

mkdir -p $out

echo "Started at 'date' "


signalp6 --fastafile ${prots} --output_dir ${out} --mode slow-sequential  --format txt

echo "Scan finished. Output files in $out"


module unload SignalP
