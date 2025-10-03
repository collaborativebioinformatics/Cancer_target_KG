library(readxl)
library(dplyr)

#load data
mut_clinvar <- read.csv("tcga_clinvar_maf.csv")
mut_all <- read.csv("coad_mut_data.csv")


mut_all <- mut_all[, -which(names(mut_all) %in% 
                              c("patient_id", "Tumor_Sample_Barcode"))]
mut_clinvar <- mut_clinvar[, -which(names(mut_clinvar)=="MC3_Sample")]
#make data frame indicating clinical significance for each gene
all_genes <- colnames(mut_all)
clinvar_genes <- colnames(mut_clinvar)

gene_clinsig <- data.frame(
  Gene=all_genes,
  Clinically_Sig=ifelse(all_genes %in% clinvar_genes, 1, 0)
)

write.csv(gene_clinsig, "clinically_sig_genes.csv", row.names = FALSE)
