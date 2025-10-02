#!/usr/bin/env bash
# clinvar_pos_in_mc3_allvcf.sh
# Keep ALL VCF columns for ClinVar records that overlap MC3 positions (position-only, ignore alleles).
# Output: /tmp/clinvar_pos_in_mc3.with_header.tsv.gz

set -euo pipefail

CLINVAR_VCF="${1:-clinvar.vcf.gz}"                # GRCh37 ClinVar VCF
MC3_BED="${2:-mc3_for_intersect.bed}"             # from generate_mc3_bed.sh
OUT_DIR="${3:-/tmp}"                               # default to /tmp (lots of space)
OUT_RAW="$OUT_DIR/clinvar_pos_in_mc3.vcfwb.tsv.gz"
OUT_HDR="$OUT_DIR/clinvar_pos_in_mc3.with_header.tsv.gz"

if [[ ! -f "$CLINVAR_VCF" ]]; then
  echo "ERROR: VCF not found: $CLINVAR_VCF" >&2; exit 1
fi
if [[ ! -f "$MC3_BED" ]]; then
  echo "ERROR: MC3 BED not found: $MC3_BED" >&2; exit 1
fi
mkdir -p "$OUT_DIR"

echo "[1/2] Intersecting (VCF vs BED, position-only)…"
# -wa = write A (VCF) record
# -wb = append B (BED) fields
# no -header (we’ll add a prefixed header ourselves)
bedtools intersect -a "$CLINVAR_VCF" -b "$MC3_BED" -wa -wb \
| awk 'BEGIN{OFS="\t"} !/^#/' \
| gzip > "$OUT_RAW"

echo "[2/2] Building prefixed header and attaching…"
# Build VCF header (prefixed with VCF_) + known MC3 BED columns (prefixed MC3_)
# We take only the last header line from VCF (the column header starting with #CHROM)
bcftools view -h "$CLINVAR_VCF" \
| awk 'END{
  # remove leading # from #CHROM
  sub(/^#/,"",$0);
  n=split($0,a,"\t");
  for(i=1;i<=n;i++){printf (i>1?"\t":"") "VCF_" a[i]}
  # Append MC3 BED column names (as produced by generate_mc3_bed.sh)
  printf "\tMC3_chrom\tMC3_start0\tMC3_end\tMC3_name\tMC3_REF\tMC3_ALT\tMC3_gene\tMC3_AA\tMC3_VarClass\tMC3_Sample\tMC3_HGVSc\tMC3_VariantType\tMC3_dbSNP\tMC3_ExistingVar\tMC3_t_depth\tMC3_t_ref\tMC3_t_alt\tMC3_n_depth\tMC3_n_ref\tMC3_n_alt\tMC3_CLIN_SIG\tMC3_FILTER\tMC3_key\n"
}' > "$OUT_DIR/header.tmp"

# Stitch header + data
{ cat "$OUT_DIR/header.tmp"; zcat "$OUT_RAW"; } | gzip > "$OUT_HDR"
rm -f "$OUT_DIR/header.tmp"

echo "Done:
  Raw (no header):   $OUT_RAW
  With header:       $OUT_HDR
"
