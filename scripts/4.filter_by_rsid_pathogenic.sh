#!/usr/bin/env bash
set -euo pipefail

IN="${1:-clinvar_mc3_merged.tsv}"
OUT="${2:-clinvar_mc3_subset.tsv}"

awk -F'\t' -v OFS='\t' '
function get_info_val(info,key,   i,kv,k,v) {
  # parse semicolon-delimited INFO; return first value for key=...
  split(info, kv, /;/)
  for (i in kv) {
    split(kv[i], k, /=/)
    if (k[1] == key) {
      v = kv[i]
      sub(/^[^=]*=/,"",v)
      return v
    }
  }
  return ""
}
function has_pathogenic(sig,   s) {
  # true if CLNSIG contains Pathogenic or Likely_pathogenic token
  # tokens are typically pipe-delimited
  s = sig
  gsub(/ /,"_",s)          # just in case
  # exact-token-ish match (allow pipes or string ends around)
  return (s ~ /(^|[|])Pathogenic([|]|$)/ || s ~ /(^|[|])Likely_pathogenic([|]|$)/)
}
BEGIN{hdr=1}
NR==1{
  # map headers
  for (i=1;i<=NF;i++) H[$i]=i
  need = "VCF_CHROM VCF_POS VCF_REF VCF_ALT VCF_INFO MC3_chrom MC3_start0 MC3_end MC3_REF MC3_ALT MC3_dbSNP"
  n=split(need,check," ")
  for(i=1;i<=n;i++){
    if(!(check[i] in H)){
      printf("ERROR: missing required column: %s\n", check[i]) > "/dev/stderr"
      exit 1
    }
  }
  print $0   # keep header
  next
}
{
  v_info  = $(H["VCF_INFO"])
  v_pos   = $(H["VCF_POS"])+0
  v_ref   = $(H["VCF_REF"])
  v_alt   = $(H["VCF_ALT"])
  v_chr   = $(H["VCF_CHROM"])

  m_chr   = $(H["MC3_chrom"])
  m_start0= $(H["MC3_start0"])+0
  m_end   = $(H["MC3_end"])+0
  m_ref   = $(H["MC3_REF"])
  m_alt   = $(H["MC3_ALT"])
  m_dbSNP = $(H["MC3_dbSNP"])

  # parse from INFO
  rs   = get_info_val(v_info, "RS")          # numeric in ClinVar VCF
  sig  = get_info_val(v_info, "CLNSIG")

  # require pathogenic / likely pathogenic
  if (!has_pathogenic(sig)) next

  # normalize rs formats (MC3 often has rsNNN or "." or "novel")
  m_rs = m_dbSNP
  gsub(/^rs/,"",m_rs)
  # allow join by rs when both present
  by_rs_ok = (rs != "" && m_rs != "" && rs == m_rs)

  # coordinate/allele match (handle 0/1-based)
  pos_ok = (v_pos == m_end) || (v_pos == (m_start0+1))
  alleles_ok = (v_ref == m_ref && v_alt == m_alt)
  coord_allele_ok = (v_chr == m_chr && pos_ok && alleles_ok)

  # keep row if rsIDs match OR (as a fallback) the exact coord+alleles match
  if (by_rs_ok || coord_allele_ok) {
    print $0
  }
}
' "$IN" > "$OUT"

printf "Wrote %s\n" "$OUT"
