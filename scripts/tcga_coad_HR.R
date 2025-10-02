# This script is to perform a survival analysis on colorectal cancer data from TCGA data.

library(tidyr)
library(dplyr)

coad_maf <- read.csv(file="data/coad_mut_data.csv")
coad_clin <- read.csv(file="data/coad_metadata.csv") %>%
  dplyr::select(-`...1`)

coad_clin <- coad_clin %>%
  mutate(age_bin = case_when(age_at_initial_pathologic_diagnosis <= 50 ~ 1, 
                             age_at_initial_pathologic_diagnosis > 50 ~ 0, 
                             TRUE ~ NA))

write.csv(coad_clin, file="data/coad_metadata.csv", row.names = FALSE)


# Read in colorectal cancer data from TCGA

# Merge mutation data with meta-data

# Create age groups (<= 50 and > 50 years old)

# Define models for young vs. old age groups

# Perform survival analysis using the survival package

## Data diagnostics: test proportional hazards assumption

## Cox model where outcome is overall survival, exposure is gene mutation status, and
## there is an interaction term for age (young vs. old)

## Plot survival curves (Kaplan-Meier plots) with separate lines for young vs. old age groups
