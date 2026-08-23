#!/bin/bash
#SBATCH --job-name=clytia_eggnog
#SBATCH --mem=64GB
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,END,TIME_LIMIT_50,TIME_LIMIT_80,TIME_LIMIT
#SBATCH --output=error_out/clytia_eggnog_%A_%a.log
#SBATCH --error=error_out/clytia_eggnog_%A_%a.err
#SBATCH --export=ALL

module load eggnogmapper
module list
prots="/lisc/data/scratch/molevo/peyroche/clytia/proteome/c_hem_nr.fasta"
out="/lisc/data/scratch/molevo/peyroche/clytia/clytia_annotations/eggnog/"

mkdir -p $out

echo "Started at 'date' "

emapper.py --go_evidence experimental -m diamond -o ${out} -i ${prots} --cpu 16 --temp_dir ${TMPDIR} 

echo "Scan finished. Output files in $out"


module unload eggnogmapper
