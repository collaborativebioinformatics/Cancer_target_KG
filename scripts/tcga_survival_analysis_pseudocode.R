# This script is to perform a survival analysis on colorectal cancer data from TCGA data.
# It will start by reading in the data using tidyverse principles, which is already cleaned,
#then using the survival# package to perform the analysis.
# We will define different models for young vs. old age groups (<= 50 and > 50 years old).
# When this is finished, we will run the same models in CPTAC data to see if the results
# are consistent.
# Additionally, we will expand the model within the CPTAC data to include proteomic markers.
# Then, we will compare this expanded model's results to the TCGA-model results.

# Read in colorectal cancer data from TCGA

# Merge mutation data with meta-data

# Create age groups (<= 50 and > 50 years old)

# Define models for young vs. old age groups

# Perform survival analysis using the survival package

## Data diagnostics: test proportional hazards assumption

## Cox model where outcome is overall survival, exposure is gene mutation status, and
## there is an interaction term for age (young vs. old)

## Plot survival curves (Kaplan-Meier plots) with separate lines for young vs. old age groups
