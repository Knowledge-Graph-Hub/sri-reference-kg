# biolink-monarch-kg

This repository contains the workflow for generating a Biolink Model compliant Monarch KG.

The purpose of this KG is to serve the following communities,
- NCATS Biomedical Data Translator
- National COVID Cohort Consortium (N3C)
- Illuminating the Druggable Genome
- KG-COVID-19


There are several ways of building a Biolink Model complaint Monarch KG.

- Read Dipper N-Triples and translate to Biolink Model
- Read SciGraph Neo4j and translate to Biolink Model


## Read Dipper N-Triples and translate to Biolink Model

This can be achieved by parsing the N-Triples through [KGX](https://github.com/NCATS-Tangerine/KGX.git).

The [monarch-transform.yaml](monarch-transform.yaml) lists all the sources that are transformed as part of this workflow. Each source has its own specific properties to facilitate the parsing of the N-Triples by KGX. The final end product of this workflow is a TSV in the [KGX interchange format](https://github.com/NCATS-Tangerine/kgx/blob/master/data-preparation.md)


## Running the workflow

There is a `Makefile` that runs the following workflow,
- Transform all Monarch N-Triples to KGX TSVs using `kgx merge`
- Load all KGX TSVs and merge into a single graph using `kgx merge`
- Create a Neo4j Docker container and load the merged graph into Neo4j using `kgx neo4j-upload`
- Compress the Neo4j data directory into an archive


