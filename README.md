# DT V1-V3 paired-end Nextflow pipeline

## DSL2 structure

```text
main.nf                         input plus visible end-to-end workflow order
subworkflows/local/raw_qc.nf    raw FastQC + MultiQC
subworkflows/local/clean_qc.nf  cleaned FastQC + MultiQC
subworkflows/local/read_cleanup.nf
subworkflows/local/qiime_import.nf
subworkflows/local/qiime_dada2.nf
subworkflows/local/qiime_taxonomy.nf
modules/local/fastqc.nf         one flat file per tool/process
modules/local/multiqc.nf
modules/local/cutadapt_v1v3.nf
modules/local/qiime_import.nf
modules/local/qiime_dada2.nf
modules/local/qiime_taxonomy.nf
conf/                           optional execution profiles
params/                         analysis parameter sets
```

This separation follows the official Nextflow DSL2 and nf-core pipeline layout. It is nf-core-inspired rather than an assertion that this private workflow is an officially released nf-core pipeline.

This workflow independently processes the two DT raw-data directories. It does not merge the datasets.

## Workflow

`raw FASTQ -> FastQC/MultiQC -> Cutadapt V1-V3 Q20 -> FastQC/MultiQC -> QIIME 2 import -> DADA2 paired -> SILVA taxonomy -> taxa barplot`

Cutadapt reproduces the supplied settings:

```text
-g AGAGTTTGATCCTGGCTCAG -a CCAGCAGCCGCGGTAAT
-G ATTACCGCGGCTGCTGG -A CTGAGCCAGGATCAAACTCT
-n 2 -q 20 -Q 20 --minimum-length 50 --discard-untrimmed
```

## Before the first run

1. Confirm the paired filename pattern is `sample_1.fastq.gz` / `sample_2.fastq.gz`.
2. Check the three Singularity image paths in `nextflow.config`.
3. If filenames use `_R1_001.fastq.gz` / `_R2_001.fastq.gz`, change each `--reads` glob in `run_both.sh` accordingly (for example `*_R{1,2}_001.fastq.gz`).

## Run datasets independently

Run `nextflow run /data/software/nextflow/amplicon_16S_v1v3_qiime_nf/main.nf` directly for each raw directory. No wrapper shell script is included.

The two result trees are:

```text
/data/home2/ksy/260811_DT_swab/Output/HN00194709_2nd_HN00182797/
/data/home2/ksy/260811_DT_swab/Output/HN00182797/
/data/home2/ksy/260811_DT_swab/Output/work/
```

Compare `01_raw_qc/multiqc`, `03_clean_qc/multiqc`, and especially `05_dada2/denoising-stats.qzv`. Prefer the dataset with good primer retention and a higher merged/non-chimeric read fraction, not merely the larger raw read count.

## SILVA taxonomy

Taxonomy is enabled by default using the classifier path from the referenced 16S workflow:

```text
/data/Reference/QIIME2-2025.7/Bacteria/SILVA/silva-138-99-nb-classifier.qza
```

If the classifier is stored elsewhere, override it with:

```bash
nextflow run main.nf -profile singularity \
  -params-file params/v1v3_q20.yml \
  --reads '/data/FASTQ/HN00182797/DT/*_{1,2}.fastq.gz' \
  --outdir results/HN00182797 \
  --classifier /data/Reference/path/to/silva-v1v3-classifier.qza \
  -resume
```

## Important V1-V3 note

V1-V3 amplicons are relatively long. Quality trimming can shorten R2 enough to prevent paired-end overlap. The initial DADA2 configuration therefore uses `trunc-len-f/r=0` after Cutadapt rather than imposing another fixed truncation. If the DADA2 merge rate is poor, inspect the cleaned-read length/quality plots and benchmark adjusted truncation or a forward-only sensitivity analysis; do not pool the two sequencing datasets as if they were different biological samples.
# amplicon_16S_v1v3_qiime_nf
