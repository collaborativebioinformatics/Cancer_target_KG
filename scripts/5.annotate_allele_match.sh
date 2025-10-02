#!/usr/bin/env bash
set -euo pipefail
IN="${1:-/dev/stdin}"
OUT="${2:-/dev/stdout}"

# Reader that handles .gz, stdin, or plain
reader() {
  local f="$1"
  if [[ "$f" == "-" || "$f" == "/dev/stdin" ]]; then
    cat
  elif [[ "$f" =~ \.gz$ ]]; then
    gzip -dc -- "$f"
  else
    cat -- "$f"
  fi
}

reader "$IN" | awk -F'\t' -v OFS='\t' '
NR==1{
  for(i=1;i<=NF;i++) H[$i]=i
  req="VCF_CHROM VCF_POS VCF_REF VCF_ALT MC3_chrom MC3_start0 MC3_end MC3_REF MC3_ALT"
  n=split(req,a," ")
  for(i=1;i<=n;i++){
    if(!(a[i] in H)){
      printf("ERROR: missing required column: %s\n", a[i]) > "/dev/stderr"
      exit 1
    }
  }
  print $0, "AlleleMatch"
  next
}
{
  vchr = $(H["VCF_CHROM"])
  vpos = $(H["VCF_POS"])+0
  vref = $(H["VCF_REF"])
  valt = $(H["VCF_ALT"])

  mchr = $(H["MC3_chrom"])
  ms0  = $(H["MC3_start0"])+0
  mend = $(H["MC3_end"])+0
  mref = $(H["MC3_REF"])
  malt = $(H["MC3_ALT"])

  same_chr   = (vchr == mchr)
  same_pos   = (vpos == mend) || (vpos == (ms0+1))
  same_alle  = (vref == mref && valt == malt)

  print $0, (same_chr && same_pos && same_alle ? "match" : "no_match")
}
' > "$OUT"
