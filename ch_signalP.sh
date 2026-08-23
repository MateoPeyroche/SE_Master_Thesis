#!/bin/bash
#SBATCH --job-name=clytia_signalP
#SBATCH --mem=64GB
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,END,TIME_LIMIT_50,TIME_LIMIT_80,TIME_LIMIT
#SBATCH --output=error_out/clytia_signalP_%A_%a.log
#SBATCH --error=error_out/clytia_signalP_%A_%a.err
#SBATCH --export=ALL

module load SignalP
module list

prots="/lisc/data/scratch/molevo/peyroche/clytia/proteome/c_hem_nr.fasta"
out="/lisc/data/scratch/molevo/peyroche/clytia/clytia_annotations/signalP/"

mkdir -p $out

echo "Started at 'date' "


signalp6 --fastafile ${prots} --output_dir ${out} --mode slow-sequential

echo "Scan finished. Output files in $out"


module unload SignalP
