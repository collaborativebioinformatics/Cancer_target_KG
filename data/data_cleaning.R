library(readxl)
library(dplyr)
#data load
mutations <- readRDS("tcga_maf_filter_binary.Rds")
metadata <- read_xlsx("TCGA-CDR-SupplementalTableS1.xlsx")
subtype_data <- read.table("TCGASubtype.20170308.tsv", sep = "\t", header = TRUE)

#intersection of samples with metadata and mutation
ids_w_muts <- unlist(lapply(mutations$Tumor_Sample_Barcode, function(x) substr(x, 1, 12)))
ids_in_both <- intersect(metadata$bcr_patient_barcode, ids_w_muts)

metadata <-  metadata[metadata$bcr_patient_barcode %in% ids_in_both,]
mutations$patient_id <- ids_w_muts
mutations<- mutations[mutations$patient_id %in% ids_in_both,]
mutations <- mutations %>% distinct(patient_id, .keep_all = TRUE)

#keep only COAD samples
mutations$type <- metadata[unlist(mapply(function(X) {which(metadata[,"bcr_patient_barcode"]==X)}, X=mutations$patient_id)), "type"]
mutations_coad <- mutations[which(mutations$type=="COAD"),]
metadata_coad <- metadata[which(metadata$type=="COAD"),]
subtype_coad <- subtype_data[which(subtype_data$cancer.type=="COAD"),]


mutations_coad <- mutations_coad[, -which(names(mutations_coad) == "type")]

#add col to meta indicating binary age
metadata_coad <- metadata_coad %>% mutate(older_than_50 = ifelse(age_at_initial_pathologic_diagnosis > 50, 1, 0))

#remove irrelevant cols
metadata_coad <- metadata_coad[, -which(names(metadata_coad) %in% 
                                c("...1", "clinical_stage", "histological_grade",
                                  "menopause_status", "Redaction", "margin_status",
                                  "residual_tumor","new_tumor_event_site","new_tumor_event_site_other",
                                  "cause_of_death", "new_tumor_event_type"))]
#download data
write.csv(metadata_coad, "coad_metadata.csv", row.names = FALSE)
write.csv(mutations_coad, "coad_mut_data.csv", quote = FALSE, row.names = FALSE)
write.csv(subtype_coad, "coad_subtype_data.csv", quote = FALSE, row.names = FALSE)
