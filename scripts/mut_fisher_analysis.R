library(epitools)
library(broom)

#load in data
meta <- read.csv("coad_metadata.csv")
mut <- read.csv("coad_mut_data.csv")
mut_rates <- read.csv("coad_mutation_rates.csv")

mut$over50 <- meta[unlist(mapply(function(X) {which(meta[,"bcr_patient_barcode"]==X)}, X=mut$patient_id)), "older_than_50"]
mut <- mut[, -which(names(mut) %in% 
                  c("Tumor_Sample_Barcode", "patient_id"))]
#remove columns where all 0 or all 1
mut <- mut[, -which(colSums(mut[,1:dim(mut)[2]-1], na.rm = FALSE, dims = 1) ==0)]

mut[colnames(mut)] <- lapply(mut[colnames(mut)], factor)

#only gene data
cols <- mut[, -which(names(mut) %in% 
                       c("over50"))]


#col wise fisher exact
res_list <- lapply(as.list(cols), function(x) fisher.test(x, y=mut$over50))
results <- do.call(rbind, lapply(res_list, broom::tidy))
results$gene <- colnames(cols)
sig_results <- results[results$p.value<0.05,]

