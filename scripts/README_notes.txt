ClinVar × MC3 — Scripts Quick Guide
===================================

1) generate_mc3_bed.sh
----------------------
Purpose:
  Convert MC3 MAF (GRCh37) to a BED-like table for bedtools, keeping key fields
  (gene, AA change, REF/ALT, sample) plus useful extras (HGVSc, VariantType, dbSNP,
  tumor/normal depths, etc.).

Inputs:
  - mc3.v0.2.8.PUBLIC.maf.gz   (tab-delimited MAF; gz or plain)

Outputs:
  - mc3_for_intersect.bed      (TAB; columns below)

Columns (first 10 match downstream expectations):
  1 MC3_chrom
  2 MC3_start0         (0-based)
  3 MC3_end            (1-based end)
  4 MC3_name           (GENE|AA|Class|REF>ALT|Sample)
  5 MC3_REF
  6 MC3_ALT
  7 MC3_gene
  8 MC3_AA             (HGVSp_Short)
  9 MC3_VarClass
 10 MC3_Sample
  -- extras appended: MC3_HGVSc, MC3_VariantType, MC3_dbSNP, MC3_ExistingVar,
     MC3_t_depth, MC3_t_ref, MC3_t_alt, MC3_n_depth, MC3_n_ref, MC3_n_alt,
     MC3_CLIN_SIG, MC3_FILTER, MC3_key (chrom:start:end:REF:ALT)

Usage:
  ./generate_mc3_bed.sh mc3.v0.2.8.PUBLIC.maf.gz mc3_for_intersect.bed

Notes:
  - Header-aware: fails with a clear message if required columns are missing.
  - Works with gz or plain input.
  - Build: GRCh37 (matches ClinVar GRCh37).


2) clinvar_pos_in_mc3_allvcf.sh
-------------------------------
Purpose:
  Position-only intersect between ClinVar VCF (GRCh37) and MC3 BED, keeping
  *all original VCF columns* (prefixed with ClinVar_) and appending MC3_ columns.

Inputs:
  - clinvar.vcf.gz             (GRCh37)
  - mc3_for_intersect.bed      (from generate_mc3_bed.sh)
  - optional OUT_DIR (default: /tmp)

Outputs:
  - OUT_DIR/clinvar_pos_in_mc3.with_header.tsv.gz
    (TSV.GZ with header; columns: ClinVar_* then MC3_*)

Usage:
  ./clinvar_pos_in_mc3_allvcf.sh clinvar.vcf.gz mc3_for_intersect.bed /tmp

Tips:
  - To restrict to Pathogenic/Likely_pathogenic, pre-filter:
    bcftools view -i 'INFO/CLNSIG[*]~"Pathogenic|Likely_pathogenic"' clinvar.vcf.gz | \
      bedtools intersect -a - -b mc3_for_intersect.bed -wa -wb
  - Writes to /tmp by default to avoid small root disk issues.


3) filter_crc_from_clinvar_mc3.sh
---------------------------------
Purpose:
  Filter clinvar_pos_in_mc3.with_header.tsv.gz to colorectal cancer rows by:
  (a) MONDO:0005575 anywhere, OR (b) CLNDN (from VCF INFO) matching CRC synonyms
  (case-insensitive; underscores/dashes normalized to spaces).

Inputs:
  - clinvar_pos_in_mc3.with_header.tsv.gz

Output:
  - crc_hits_by_condition.tsv   (header preserved; full rows kept)

Usage:
  ./filter_crc_from_clinvar_mc3.sh clinvar_pos_in_mc3.with_header.tsv.gz crc_hits_by_condition.tsv

Notes:
  - Edit the synonym list inside the script to expand/alter matching terms.
  - Looks for VCF_INFO column name in the header (as produced by #2).


4) filter_by_rsid_pathogenic.sh
-------------------------------
Purpose:
  Subset the ClinVar×MC3 TSV to rows whose VCF ID/INFO indicate a matching dbSNP
  rsID and whose clinical significance is Pathogenic/Likely_pathogenic.

Typical Inputs:
  - clinvar_pos_in_mc3.with_header.tsv.gz
  - (optional) rsid list file: one rsID per line, e.g. rs12345

Outputs:
  - filtered_by_rsid_pathogenic.tsv  (full rows, header preserved)

Expected Behavior:
  - If an rsID list is provided, keeps rows where VCF_ID ∈ list.
  - Always enforces CLNSIG contains "Pathogenic" or "Likely_pathogenic" in VCF_INFO.

Usage:
  # by rsid list + significance
  ./filter_by_rsid_pathogenic.sh clinvar_pos_in_mc3.with_header.tsv.gz rsids.txt filtered.tsv

  # significance-only (no rsid list)
  ./filter_by_rsid_pathogenic.sh clinvar_pos_in_mc3.with_header.tsv.gz filtered.tsv

Notes:
  - Case-insensitive match on CLNSIG; tolerant to composite values.
  - If VCF_ID is ".", will rely only on CLNSIG unless script variant also parses RS= in INFO.


5) annotate_allele_match.sh
---------------------------
Purpose:
  Given the position-only joined table, add an "AlleleMatch" flag by comparing
  MC3_REF/MC3_ALT to ClinVar REF/ALT (exact match), so downstream consumers can
  distinguish exact vs position-only hits in a single file.

Inputs:
  - clinvar_pos_in_mc3.with_header.tsv.gz  (or .tsv)
    Required columns: ClinVar_REF, ClinVar_ALT, MC3_REF, MC3_ALT

Output:
  - with_allele_match.tsv(.gz)   (same columns + new AlleleMatch: exact|position_only)

Usage:
  ./annotate_allele_match.sh clinvar_pos_in_mc3.with_header.tsv.gz with_allele_match.tsv

Notes:
  - Does not drop rows; purely annotates.
  - If multiple ClinVar ALTs per position exist, flag is per-row comparison.


Dependencies (all scripts)
--------------------------
- bash, awk, gzip
- bedtools (for intersect)
- bcftools (for header extraction / optional filtering)
- Input data are GRCh37-aligned (MC3 and ClinVar).


Operational Notes
-----------------
- Disk space: prefer writing big intermediates to /tmp (tmpfs) or compress outputs (.gz).
- Reproducibility: scripts are header-aware and avoid hardcoded column indices (where possible).
- Exact vs position-only:
  - Position-only: use #2 (it already ignores alleles).
  - Exact allele subsets: either run a post-filter 


Provenance
----------
- Date: October 2, 2025 (UTC+01:00)
- Scripts sizes (approx):
  1. generate_mc3_bed.sh              ~2.0 KB
  2. clinvar_pos_in_mc3_allvcf.sh     ~2.0 KB
  3. filter_crc_from_clinvar_mc3.sh   ~2.1 KB
  4. filter_by_rsid_pathogenic.sh     ~2.2 KB
  5. annotate_allele_match.sh         (size as listed)
