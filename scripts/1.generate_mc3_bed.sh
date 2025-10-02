#!/usr/bin/env bash
# generate_mc3_bed.sh
set -euo pipefail

IN="${1:-mc3.v0.2.8.PUBLIC.maf.gz}"
OUT="${2:-mc3_for_intersect.bed}"

if [[ ! -f "$IN" ]]; then
  echo "ERROR: input file not found: $IN" >&2
  exit 1
fi

# reader for gz or plain
if [[ "$IN" == *.gz ]]; then
  READER=("gzip" "-cd" "--")
else
  READER=("cat" "--")
fi

"${READER[@]}" "$IN" | awk -F'\t' '
function G(k,   v) {                # safe getter for optional fields
  if (k in idx && idx[k] > 0) { v = $(idx[k]); if (v=="") v="."; return v }
  return "."
}
BEGIN{OFS="\t"}
NR==1{
  for(i=1;i<=NF;i++) idx[$i]=i
  # required columns
  split("Hugo_Symbol Chromosome Start_Position End_Position Reference_Allele Tumor_Seq_Allele2 Variant_Classification HGVSp_Short HGVSc Tumor_Sample_Barcode", R, " ")
  for(j in R) if(!(R[j] in idx)){print "Missing column:",R[j] > "/dev/stderr"; exit 1}

  # optional columns (graceful if absent)
  split("Variant_Type dbSNP_RS Existing_variation t_depth t_ref_count t_alt_count n_depth n_ref_count n_alt_count CLIN_SIG FILTER", O, " ")
  for(j in O) if(!(O[j] in idx)) idx[O[j]]=0
  next
}
{
  chrom = $(idx["Chromosome"])
  start0 = $(idx["Start_Position"]) - 1
  end    = $(idx["End_Position"])
  ref    = $(idx["Reference_Allele"])
  alt    = $(idx["Tumor_Seq_Allele2"])
  gene   = $(idx["Hugo_Symbol"])
  aa     = $(idx["HGVSp_Short"])
  vcls   = $(idx["Variant_Classification"])
  samp   = $(idx["Tumor_Sample_Barcode"])
  hgvs_c = $(idx["HGVSc"])

  vtype  = G("Variant_Type")
  rsid   = G("dbSNP_RS")
  exist  = G("Existing_variation")
  td     = G("t_depth");  tr = G("t_ref_count");  ta = G("t_alt_count")
  nd     = G("n_depth");  nr = G("n_ref_count");  na = G("n_alt_count")
  clns   = G("CLIN_SIG")
  filt   = G("FILTER")

  name = gene"|"aa"|"vcls"|"ref">"alt"|"samp
  key  = chrom":"(start0+1)":"end":"ref":"alt

  # first 10 (original layout) + extras
  print chrom, start0, end, name, ref, alt, gene, aa, vcls, samp, \
        hgvs_c, vtype, rsid, exist, td, tr, ta, nd, nr, na, clns, filt, key
}' > "$OUT"

echo "Wrote: $OUT" >&2
