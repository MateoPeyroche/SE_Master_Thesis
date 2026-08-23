#!/bin/bash
#SBATCH --job-name=sanma_eggnog
#SBATCH --mem=64GB
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,END,TIME_LIMIT_50,TIME_LIMIT_80,TIME_LIMIT
#SBATCH --output=error_out/sanma_eggnog_%j.log
#SBATCH --error=error_out/sanma_eggnog_%j.err
#SBATCH --export=ALL
#SBATCH --cpus-per-task=16

module load eggnogmapper
module list
prots="/lisc/data/scratch/molevo/peyroche/clytia/clytia_ortho_search/data/proteomes/Sanma_proteome_1p1g.fasta"
out="/lisc/data/scratch/molevo/peyroche/sanderia/annotations/eggnog/"

mkdir -p $out

echo "Started at 'date' "

emapper.py --go_evidence experimental -m diamond --output_dir ${out} -o sanderia  -i ${prots} --cpu 16 --temp_dir ${TMPDIR} 

echo "Scan finished. Output files in $out"


module unload eggnogmapper
