#!/usr/bin/env bash
#
# top_blast_hits.sh
#
# Extract the top N hits per query from a BLAST tabular results file
# (outfmt 6 or 7). Works on multi-query files where results for
# several queries are concatenated together.
#
# BLAST already sorts hits per query best-first (by E-value / bit score),
# so this script simply keeps the first N data lines seen for each
# query, identified by column 1 (the query ID).
#
# Usage:
#   ./top_blast_hits.sh <input_file> <top_n> [output_file]
#
# Examples:
#   ./top_blast_hits.sh blast_results.tsv 20
#   ./top_blast_hits.sh blast_results.tsv 30 top_hits.tsv

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <input_file> <top_n> [output_file]" >&2
    exit 1
fi

INPUT="$1"
TOP_N="$2"
OUTPUT="${3:-/dev/stdout}"

if [[ ! -f "$INPUT" ]]; then
    echo "Error: input file '$INPUT' not found." >&2
    exit 1
fi

if ! [[ "$TOP_N" =~ ^[0-9]+$ ]] || [[ "$TOP_N" -lt 1 ]]; then
    echo "Error: top_n must be a positive integer." >&2
    exit 1
fi

gawk -v n="$TOP_N" '
    # Lines starting with "#" are comments (outfmt 7 headers/footers).
    # Pass them through untouched -- they do not count toward the
    # per-query line limit, and the "# Query:" line is a convenient
    # explicit reset point for outfmt 7 files.
    /^#/ {
        print
        if ($0 ~ /^# Query:/) {
            # reset counter for the upcoming query block
            current_query = ""
            count = 0
        }
        next
    }

    # Data line: column 1 is the query ID.
    {
        query = $1
        if (query != current_query) {
            # First time we see this query ID -> new block starts
            current_query = query
            count = 0
        }
        count++
        if (count <= n) {
            print
        }
    }
' "$INPUT" > "$OUTPUT"

if [[ "$OUTPUT" != "/dev/stdout" ]]; then
    echo "Done. Top $TOP_N hits per query written to: $OUTPUT" >&2
fi
