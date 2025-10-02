library(dplyr)

#data load in
metadata<-read.csv("./data/coad_metadata.csv")

#remove odd/no data cols
metadata <- metadata[, -which(names(metadata) %in% 
                                c("...1", "clinical_stage", "histological_grade",
                                 "menopause_status", "Redaction", "margin_status",
                                 "residual_tumor","new_tumor_event_site","new_tumor_event_site",
                                 "cause_of_death"))]
