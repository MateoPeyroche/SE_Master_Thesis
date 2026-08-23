#!/bin/bash
#SBATCH --job-name=clytia_ortho_search
#SBATCH --mem=64GB
#SBATCH --time=1-00:00:00
#SBATCH --mail-type=BEGIN,END,TIME_LIMIT_50,TIME_LIMIT_80,TIME_LIMIT
#SBATCH --output=error_out/clytia_os_%A_%a.log
#SBATCH --error=error_out/clytia_os_%A_%a.err
#SBATCH --export=ALL
module list || true
set -euo pipefail
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"
export LD_PRELOAD="${LD_PRELOAD:-}"
export MANPATH="${MANPATH:-}"
export MODULEPATH="${MODULEPATH:-}"

# Run module commands with nounset temporarily disabled (the `module`
# function references unset vars internally on this cluster).
with_modules_off_u () {
    set +u
    "$@"
    set -u
}

###############################################################################
# CONFIG
###############################################################################
# Space-separated list of BLAST outfmt 7 files (same proteins, same order)
BASEDIR="/lisc/data/scratch/molevo/peyroche/clytia_ortho_search"
BLAST_FILES=("$BASEDIR/data/blast_files/pelagia_bilat_muscle_tfs_for_ortho_top30.txt" \
             "$BASEDIR/data/blast_files/aurelia_bilat_muscle_tfs_for_ortho_top30.txt" \
             "$BASEDIR/data/blast_files/sanderia_bilat_muscle_tfs_for_ortho_top30.txt")

# Proteome FASTA files that made up the BLAST database
PROTEOMES=("$BASEDIR"/data/proteomes/*.fasta)
if [[ ! -e "${PROTEOMES[0]}" ]]; then
    echo "ERROR: no proteome files found under $BASEDIR/data/proteomes/" >&2
    exit 1
fi

# TSV whose first column gives the output basename for each protein.
# Row N (after the header) names the Nth BLAST search. Has a header row.
NAME_TSV="$BASEDIR/data/name_IDs/bilat_muscle_tf_for_OrthoSearch.tsv"

# Output directories
OUTDIR="$BASEDIR/results"
SEQ_DIR="$OUTDIR/sequences"
ALN_DIR="$OUTDIR/alignments"
TRIM_DIR="$OUTDIR/trimmed"
TREE_DIR="$OUTDIR/trees"

# IQ-TREE 3 settings
BOOTSTRAP=1000          # ultrafast bootstrap replicates (min recommended 1000)
THREADS=4               # also passed to IQ-TREE as -T

mkdir -p "$SEQ_DIR" "$ALN_DIR" "$TRIM_DIR" "$TREE_DIR"

###############################################################################
# Helpers
###############################################################################
get_query_names () {
    grep '^# Query:' "$1" | sed 's/^# Query:[[:space:]]*//'
}

# Print the hit IDs (subject = column 2) of the Nth query block (1-based).
ids_for_block () {
    local file="$1" idx="$2"
    awk -v target="$idx" '
        /^# Query:/ { block++ }
        block == target && !/^#/ && NF { print $2 }
    ' "$file"
}

###############################################################################
# Load output names and sanity-check against number of BLAST searches
###############################################################################
mapfile -t NAMES < <(awk -F'\t' 'NR>1 {print $1}' "$NAME_TSV")
mapfile -t QUERY_NAMES < <(get_query_names "${BLAST_FILES[0]}")
NPROT=${#QUERY_NAMES[@]}

if [[ "${#NAMES[@]}" -ne "$NPROT" ]]; then
    echo "ERROR: $NAME_TSV has ${#NAMES[@]} name rows but the BLAST files contain $NPROT searches." >&2
    echo "These must match (one name per BLAST search)." >&2
    exit 1
fi
echo "Found $NPROT proteins across ${#BLAST_FILES[@]} BLAST files."

# Precompute the sanitized basename for every protein, reused across phases.
SAFE_NAMES=()
for (( i=1; i<=NPROT; i++ )); do
    raw_name="${NAMES[$((i-1))]}"
    SAFE_NAMES+=("$(echo "$raw_name" | tr -c 'A-Za-z0-9._-' '_')")
done

###############################################################################
# PHASE 1: Build DB + extract sequences (SeqKit)
###############################################################################
with_modules_off_u module load SeqKit

COMBINED="$OUTDIR/combined_proteomes.fasta"
if [[ ! -s "$COMBINED" ]]; then
    cat "${PROTEOMES[@]}" > "$COMBINED"
    seqkit faidx "$COMBINED" >/dev/null
fi

for (( i=1; i<=NPROT; i++ )); do
    qname="${QUERY_NAMES[$((i-1))]}"
    safe_name="${SAFE_NAMES[$((i-1))]}"
    echo "[extract $i/$NPROT] '$qname' -> '$safe_name'"

    id_file="$SEQ_DIR/${safe_name}.ids.txt"
    for bf in "${BLAST_FILES[@]}"; do
        ids_for_block "$bf" "$i"
    done | sort -u > "$id_file"

    n_ids=$(wc -l < "$id_file")
    fasta_out="$SEQ_DIR/${safe_name}.fasta"
    seqkit grep -f "$id_file" "$COMBINED" > "$fasta_out"

    n_found=$(grep -c '^>' "$fasta_out" || true)
    echo "      $n_ids requested, $n_found found"
    if [[ "$n_found" -ne "$n_ids" ]]; then
        echo "      WARNING: mismatch for $safe_name" >&2
    fi
done

with_modules_off_u module unload SeqKit

###############################################################################
# PHASE 2: Align everything (MAFFT)
###############################################################################
with_modules_off_u module load MAFFT

for (( i=1; i<=NPROT; i++ )); do
    safe_name="${SAFE_NAMES[$((i-1))]}"
    echo "[align $i/$NPROT] $safe_name"
    mafft --auto --thread "$THREADS" \
          "$SEQ_DIR/${safe_name}.fasta" > "$ALN_DIR/${safe_name}.aln.fasta"
done

with_modules_off_u module unload MAFFT

###############################################################################
# PHASE 3: Trim everything (trimAl)
###############################################################################
with_modules_off_u module load trimAl

for (( i=1; i<=NPROT; i++ )); do
    safe_name="${SAFE_NAMES[$((i-1))]}"
    echo "[trim $i/$NPROT] $safe_name"
    trimal -in "$ALN_DIR/${safe_name}.aln.fasta" \
           -out "$TRIM_DIR/${safe_name}.trim.fasta" -automated1
done

with_modules_off_u module unload trimAl

###############################################################################
# PHASE 4: Build trees (IQ-TREE 3)
###############################################################################
with_modules_off_u module load IQ-TREE/3.0.1

for (( i=1; i<=NPROT; i++ )); do
    safe_name="${SAFE_NAMES[$((i-1))]}"
    echo "[tree $i/$NPROT] $safe_name"
    iqtree3 -s "$TRIM_DIR/${safe_name}.trim.fasta" \
            -m MFP -B "$BOOTSTRAP" -T AUTO \
            --prefix "$TREE_DIR/${safe_name}" -redo
done

with_modules_off_u module unload IQ-TREE/3.0.1

echo "Done. Trees in $TREE_DIR"
