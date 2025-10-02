# Cancer Target Knowledge Graph

## Overview
This project builds a knowledge graph integrating cancer genomics data to identify potential biomarkers and therapeutic targets. We focus on colorectal adenocarcinoma (COAD) because it is well-represented in both TCGA (The Cancer Genome Atlas) and CPTAC (Clinical Proteomic Tumor Analysis Consortium) datasets, enabling cross-platform validation.

## Project Approach
Our analysis strategy involves three key steps:

1. Model Development in TCGA: Build a survival prediction model for colorectal adenocarcinoma using genetic markers from TCGA data
2. Cross-Platform Validation: Test how well the TCGA-derived model performs when applied to CPTAC data
3. Model Enhancement: Expand the model in CPTAC by incorporating both the original genetic markers and CPTAC's proteomic data to assess whether protein-level information improves predictive accuracy

We perform survival analysis stratified by age groups (≤50 vs >50 years old) and report hazard ratios with 95% confidence intervals to identify age-specific biomarkers and therapeutic targets.

## Knowledge Graph Construction
The primary goal of this project is to construct a comprehensive knowledge graph that captures relationships between genes, mutations, proteins, clinical outcomes, and patient characteristics. The repository documents our methodology for determining which entities should be represented as nodes and which relationships should be represented as edges in the graph structure.
Getting Started

See the flowchart and schema diagrams in this repository for a visual overview of the project workflow and knowledge graph design.

# Flowchart

![Overview diagram](initial_flow_chart.png)

# Brainstorming Knowledge Graph Schema

![Overview diagram](draft_knowledge_graph_schema.png)
