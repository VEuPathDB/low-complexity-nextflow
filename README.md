# low-complexity-nextflow

A Nextflow pipeline that masks low-complexity regions in nucleotide or protein sequences.

## Overview

This pipeline identifies low-complexity regions in an input FASTA file using NCBI's `dustmasker` (for nucleotide sequences) or `seg` (for protein sequences), and produces a sorted, indexed BED file of the masked intervals. It is used within VEuPathDB's genome annotation workflows to flag low-complexity regions of a genome or proteome so they can be excluded from or annotated separately in downstream analyses such as similarity searches. The input FASTA is split into subsets for parallel masking, the raw interval output is converted to BED coordinates, and the combined results are sorted, compressed with `bgzip`, and indexed with `tabix`.

## Requirements

- [Nextflow](https://www.nextflow.io/) (DSL2)
- Docker (a `docker.config` profile is included; `singularity` and `lsf` config files are also provided)

The pipeline uses the `veupathdb/blastsimilarity:1.0.0` container (built from the included `Dockerfile`, which extends `veupathdb/blastsimilarity` with the `seg` tool) for masking, and `bioperl/bioperl:stable` and `biocontainers/tabix:v1.9-11-deb_cv1` for BED conversion and indexing.

## Usage

The pipeline provides two built-in Nextflow profiles that select the input sequence type and masking program: `aa` (protein sequences, masked with `seg`) and `na` (nucleotide sequences, masked with `dustmasker`).

```
nextflow run VEuPathDB/low-complexity-nextflow \
  -r main \
  -profile na,docker \
  --inputFilePath /path/to/genome.fa \
  --outputDir /path/to/output \
  --outputFileName lowComplexity-na.bed \
  -resume
```

The pipeline has a single, unnamed workflow entry point that runs the full process: splitting the input FASTA, masking each subset with the program selected by `params.seqType`, converting the results to BED, and sorting/compressing/indexing the output.

## Key Parameters

| Parameter | Description |
| --- | --- |
| `params.inputFilePath` | Path to the input FASTA file (nucleotide or protein) to mask. |
| `params.seqType` | Sequence type: `aa` (protein, masked with `seg`) or `na` (nucleotide, masked with `dustmasker`); set automatically by the `aa`/`na` profiles. |
| `params.fastaSubsetSize` | Number of sequences per FASTA subset sent to a single masking process; controls the degree of parallelism. |
| `params.outputFileName` | File name for the final BED output (e.g. `lowComplexity-na.bed` or `lowComplexity-aa.bed`). |
| `params.outputDir` | Directory where the final `.bed.gz` and `.tbi` index are published. |

## Output

A `bgzip`-compressed, `tabix`-indexed BED file (`<outputFileName>.gz` and its `.tbi` index) listing the low-complexity intervals found across the input sequences, sorted by sequence and start coordinate.
