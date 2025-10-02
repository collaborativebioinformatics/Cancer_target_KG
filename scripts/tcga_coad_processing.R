# This script is to perform a survival analysis on colorectal cancer data from TCGA data.

library(tidyr)
library(dplyr)

coad_maf <- read.csv(file="data/coad_mut_data.csv")
coad_clin <- read.csv(file="data/coad_metadata.csv") 


# filter genes 
sum_gg <- coad_maf %>% 
  dplyr::select(-c(Tumor_Sample_Barcode, patient_id)) %>%
  apply(., 2, sum)

# do a filter of <2%

# read in csv file 

gene_prop <- read.csv(file="data/coad_mutation_rates.csv")

gg_cut_off <- 0.02

#gg_cut_off = 1

gene_prop_filter <- gene_prop %>% dplyr::filter(Frequency > gg_cut_off)

#this leads to about 6344 genes

coad_maf_filter <- coad_maf %>% dplyr::select(patient_id, all_of(gene_prop_filter$Gene))

# cox model with interaction term  

# The HR is calculated on all genes except singeltons 

coad_combine <- coad_maf_filter %>%
  dplyr::rename("bcr_patient_barcode" = patient_id) %>%
  inner_join(coad_clin %>% dplyr::select(bcr_patient_barcode, OS.time, OS, older_than_50), by = "bcr_patient_barcode")

# age + gene_mut + age:gene_mut

#if older_than_50 = 1
# if a gene_mutated = 1
# interpret HR as mutated fo rthat gene in older than 50 group vs WT and younger than 50 group 

gene_hr_pval <- NULL

for(i in 1:nrow(gene_prop_filter)){
  
  gg = gene_prop_filter$Gene[i]
  dat <- coad_combine %>%
    dplyr::select(all_of(gg), OS.time, OS, older_than_50) %>%
    dplyr::rename("gene_mut" = eval(gg))
  
  mod <- coxph(Surv(OS.time, OS) ~ older_than_50 + gene_mut + gene_mut:older_than_50, data = dat)
  hr_coef <- summary(mod)$coef[3,"exp(coef)"]
  hr_pval <- summary(mod)$coef[3,"Pr(>|z|)"]
  
  gene_hr_pval <- rbind.data.frame(gene_hr_pval, data.frame(gene = gg, exp_hr_coef = hr_coef, hr_pval = hr_pval))
  
}
  
  
write.csv(gene_hr_pval, file="data/gene_0.02thr_HR_pval.csv")

  

#on the same genes add pathway information 

library(msigdbr)

human_canoncial_pways <- msigdbr(species = "Homo sapiens", category = "C2")

human_canoncial_pways_filter <- human_canoncial_pways %>%
  dplyr::filter(gs_subcat %in% c("CP:BIOCARTA", "CP:KEGG", "CP:REACTOME"))

#filter pathways with more than 200 genes 

# human_canoncial_pways_filter <- human_canoncial_pways_filter %>%
#   group_by(gs_name) %>%
#   mutate(n_genes = n()) %>%
#   ungroup() %>%
#   dplyr::filter(n_genes <= 200)


human_canoncial_pways_filter_wide <- human_canoncial_pways_filter %>%
  dplyr::select(gs_name, gene_symbol) %>%
  distinct() %>%
  pivot_wider(id_cols = gene_symbol, names_from = gs_name, 
              values_from = gs_name, values_fill = 0, values_fn = function(x) 1)

#filter on genes that are less prevalent 

human_canoncial_pways_filter_wide <- human_canoncial_pways_filter_wide %>%
  dplyr::filter(gene_symbol %in% gene_prop_filter$Gene) %>%
  dplyr::rename("gene" = gene_symbol)


write.csv(human_canoncial_pways_filter_wide, file="data/human_canonical_pways.csv", row.names = FALSE)



