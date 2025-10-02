#!/usr/bin/env bash
# filter_crc_from_clinvar_mc3.sh
# Usage:
#   ./filter_crc_from_clinvar_mc3.sh clinvar_pos_in_mc3.with_header.tsv.gz [out.tsv]
# Notes:
#   - Keeps full rows/columns (header preserved)
#   - Matches MONDO:0005575 anywhere OR CLNDN in ClinVar INFO against CRC synonyms

set -euo pipefail

IN="${1:-clinvar_pos_in_mc3.with_header.tsv.gz}"
OUT="${2:-crc_hits_by_condition.tsv}"

if [[ ! -f "$IN" ]]; then
  echo "ERROR: input not found: $IN" >&2
  exit 1
fi

# Temp terms file (CRC synonyms + MONDO id handled separately)
TERMS_FILE="$(mktemp)"
cat > "$TERMS_FILE" << 'EOF'
colorectal cancer
crc
cancer of colorectum
cancer of large bowel
cancer of large intestine
colon cancer
colorectum cancer
large intestine cancer
malignant colorectal neoplasm
malignant colorectal tumor
malignant colorectal tumour
malignant neoplasm of colorectum
malignant neoplasm of large bowel
malignant neoplasm of large intestine
EOF

# Decide reader (gz or plain)
if [[ "$IN" == *.gz ]]; then
  READER=(zcat --)
else
  READER=(cat --)
fi

# Do the filtering
"${READER[@]}" "$IN" | awk -F'\t' -v TERMS="$TERMS_FILE" '
BEGIN{
  OFS="\t"; IGNORECASE=1;
  # load terms; normalize underscores/dashes to spaces, tolower
  while ((getline t < TERMS)>0) {
    gsub(/[_-]/," ", t);
    for (i=1;i<=length(t);i++) t2 = tolower(t);  # portable tolower()
    t2 = tolower(t);
    if (t2!="") terms[t2]=1
  }
}
NR==1{
  # find the ClinVar INFO column (named VCF_INFO in your file)
  for (i=1;i<=NF;i++) if ($i=="VCF_INFO") info_idx=i;
  if (!info_idx) { print "ERROR: VCF_INFO column not found" > "/dev/stderr"; exit 1 }
  print; next
}
{
  # quick path: MONDO id anywhere in the row
  if (index($0, "MONDO:0005575")) { print; next }

  info=$info_idx
  # extract CLNDN=... from INFO
  split(info, a, ";"); clndn=""
  for (i in a) {
    if (a[i] ~ /^CLNDN=/) { clndn = substr(a[i], 8); break }
  }
  if (clndn=="") next

  # normalize CLNDN: underscores/dashes -> spaces; tolower
  norm = clndn
  gsub(/[_-]/," ", norm)
  norm = tolower(norm)

  # check against any term
  for (t in terms) {
    if (index(norm, t)) { print; break }
  }
}
' > "$OUT"

rm -f "$TERMS_FILE"
echo "Wrote: $OUT"
