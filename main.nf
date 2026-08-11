nextflow.enable.dsl = 2

params.reads = null
params.outdir = 'results'

include { RAW_QC } from './subworkflows/local/raw_qc'
include { READ_CLEANUP } from './subworkflows/local/read_cleanup'
include { CLEAN_QC } from './subworkflows/local/clean_qc'
include { QIIME_IMPORT_WORKFLOW } from './subworkflows/local/qiime_import'
include { QIIME_DADA2_WORKFLOW } from './subworkflows/local/qiime_dada2'
include { QIIME_TAXONOMY_WORKFLOW } from './subworkflows/local/qiime_taxonomy'

workflow {
    if (!params.reads) {
        error 'Provide --reads, e.g. /data/run/*_{1,2}.fastq.gz'
    }

    reads_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true, flat: true)
        .map { id, r1, r2 -> tuple([id: id.toString(), single_end: false], r1, r2) }

    // 1. Raw-read FastQC and MultiQC.
    RAW_QC(reads_ch)

    // 2. V1-V3 primer removal and Q20 quality trimming.
    READ_CLEANUP(reads_ch)

    // 3. FastQC and MultiQC after Cutadapt.
    CLEAN_QC(READ_CLEANUP.out.cleaned_reads)

    // 4. Collect all cleaned FASTQ files and import as paired-end QIIME data.
    clean_fastqs_ch = READ_CLEANUP.out.cleaned_reads
        .flatMap { meta, r1, r2 -> [r1, r2] }
        .collect()

    QIIME_IMPORT_WORKFLOW(clean_fastqs_ch)

    // 5. Paired-end DADA2 denoising, merging and chimera removal.
    QIIME_DADA2_WORKFLOW(QIIME_IMPORT_WORKFLOW.out.demux)

    // 6. SILVA taxonomy assignment and taxa bar plot.
    classifier_ch = Channel.fromPath(params.classifier, checkIfExists: true)
    QIIME_TAXONOMY_WORKFLOW(
        QIIME_DADA2_WORKFLOW.out.repseq,
        QIIME_DADA2_WORKFLOW.out.table,
        QIIME_IMPORT_WORKFLOW.out.manifest,
        classifier_ch
    )
}
