#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Keep only the longest protein per gene from a proteome FASTA.
# Usage: bash longest_per_gene.sh <proteome.fasta> <gene_map.tsv> <out.fasta>
#   gene_map.tsv : two columns, protein_id <TAB> gene_id (no header)
###############################################################################

if [[ $# -ne 3 ]]; then
    echo "Usage: bash $0 <proteome.fasta> <gene_map.tsv> <out.fasta>" >&2
    exit 1
fi

PROTEOME="$1"
MAP="$2"
OUT="$3"

# Basic existence checks
for f in "$PROTEOME" "$MAP"; do
    if [[ ! -s "$f" ]]; then
        echo "Error: '$f' is missing or empty." >&2
        exit 1
    fi
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 1. Get length of every protein: ID <TAB> length
seqkit fx2tab --length --name --only-id "$PROTEOME" \
    | awk '{print $1"\t"$NF}' > "$TMP/lengths.tmp"

# 2. Join lengths with gene mapping, pick longest protein per gene
sort -k1,1 "$TMP/lengths.tmp" > "$TMP/lengths.sorted"
sort -k1,1 "$MAP" > "$TMP/map.sorted"

join -1 1 -2 1 "$TMP/map.sorted" "$TMP/lengths.sorted" \
    | awk '
        # fields: protein_id gene_id length
        {
            if ($3 > best_len[$2]) {
                best_len[$2] = $3
                best_prot[$2] = $1
            }
        }
        END { for (g in best_prot) print best_prot[g] }
    ' > "$TMP/keep_ids.txt"

# 3. Extract the winning proteins
seqkit grep -f "$TMP/keep_ids.txt" "$PROTEOME" > "$OUT"

# Report
n_genes=$(wc -l < "$TMP/keep_ids.txt")
echo "$PROTEOME: kept $n_genes proteins (one per gene) -> $OUT"
