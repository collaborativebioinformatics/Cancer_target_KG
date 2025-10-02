
##make wide format of Carmens's file 

tt = read.delim(file="~/Downloads/clinvar_pos_in_mc3.with_header_filtered.annot.tsv", sep="\t")

tt_wide <- tt %>% 
  dplyr::filter(MC3_FILTER == "PASS") %>% 
  dplyr::select(MC3_Sample, MC3_gene) %>% distinct() %>% 
  pivot_wider(id_cols = MC3_Sample, names_from = MC3_gene, values_from = MC3_gene, 
              values_fill = 0, values_fn = function(x) 1)

write.csv(file=tt_wide, file="data/tcga_clinvar_maf.csv")