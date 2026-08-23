#!/bin/bash
#SBATCH --job-name=clytia_interproscan
#SBATCH --mem=64GB
#SBATCH --cpus-per-task=16
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,END,TIME_LIMIT_50,TIME_LIMIT_80,TIME_LIMIT
#SBATCH --output=error_out/clytia_interpro_%j.log
#SBATCH --error=error_out/clytia_interpro_%j.err
#SBATCH --export=ALL

module load InterProScan
module list

out="/lisc/data/scratch/molevo/peyroche/clytia/clytia_annotations/interpro/"
prots="/lisc/data/scratch/molevo/peyroche/clytia/proteome/c_hem_nr.fasta"

mkdir -p $out 

echo "Started at 'date' "

interproscan.sh -cpu 16 -b "${out}" -etra -f GFF3,TSV,XML -goterms -i "${prots}"  -t p -pa

echo "Scan finished. Output files in $out"

module unload InterProScan
