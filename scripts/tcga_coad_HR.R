# This script is to perform a survival analysis on colorectal cancer data from TCGA data.

library(tidyr)
library(dplyr)

coad_maf <- read.csv(file="data/coad_mut_data.csv")
coad_clin <- read.csv(file="data/coad_metadata.csv") %>%
  dplyr::select(-`...1`)


# filter genes 
sum_gg <- coad_maf %>% 
  dplyr::select(-c(Tumor_Sample_Barcode, patient_id)) %>%
  apply(., 2, sum)

# do a filter of <2%

gg_cut_off <- round(length(unique(coad_maf$Tumor_Sample_Barcode)) * 0.02)

sum_gg_filter <- sum_gg[which(sum_gg > gg_cut_off)]

coad_maf_filter <- coad_maf %>% dplyr::select(patient_id, all_of(names(sum_gg_filter)))

# cox model 

for(i in 1:length(sum_gg_filter)){
  
  
  
  
  
}


#on the same genes add pathway information 

library(msigdbr)

human_canoncial_pways <- msigdbr(species = "Homo sapiens", category = "C2")

human_canoncial_pways_filter <- human_canoncial_pways %>%
  dplyr::filter(gs_subcat %in% c("CP:BIOCARTA", "CP:KEGG", "CP:REACTOME"))

#filter pathways with more than 200 genes 

human_canoncial_pways_filter <- human_canoncial_pways_filter %>%
  group_by(gs_name) %>%
  mutate(n_genes = n()) %>%
  ungroup() %>%
  dplyr::filter(n_genes <= 200)


human_canoncial_pways_filter_wide <- human_canoncial_pways_filter %>%
  dplyr::select(gs_name, gene_symbol) %>%
  distinct() %>%
  pivot_wider(id_cols = gene_symbol, names_from = gs_name, 
              values_from = gs_name, values_fill = 0, values_fn = function(x) 1)

#filter on genes that are less prevalent 

human_canoncial_pways_filter_wide <- human_canoncial_pways_filter_wide %>%
  dplyr::filter(gene_symbol %in% names(sum_gg_filter))


write.csv(human_canoncial_pways_filter_wide, file="data/human_canonical_pways.csv", row.names = FALSE)



