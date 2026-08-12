nextflow.enable.dsl = 2

params.reads = null
params.outdir = 'results'

include { RAW_QC } from './subworkflows/local/raw_qc'
include { READ_CLEANUP } from './subworkflows/local/read_cleanup'
include { CLEAN_QC } from './subworkflows/local/clean_qc'
include { QIIME_IMPORT_WORKFLOW } from './subworkflows/local/qiime_import'
include { QIIME_DADA2_WORKFLOW } from './subworkflows/local/qiime_dada2'
include { QIIME_TAXONOMY_WORKFLOW } from './subworkflows/local/qiime_taxonomy'
include { QIIME_PHYLOGENY_WORKFLOW } from './subworkflows/local/qiime_phylogeny'
include { QIIME_DIVERSITY_WORKFLOW } from './subworkflows/local/qiime_diversity'
include { TRIMM_OPTIMAL_WORKFLOW } from './subworkflows/local/trimm_optimal'

workflow {
    if (!params.reads) {
        error 'Provide --reads, e.g. /data/run/*_{1,2}.fastq.gz'
    }
    if (!params.metadata) {
        error 'Provide --metadata with a QIIME 2-compatible TSV file'
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

    metadata_ch = Channel.value(file(params.metadata, checkIfExists: true))
    classifier_file = file(params.classifier, checkIfExists: true)
    classifier_ch = Channel.value(classifier_file)

    taxonomy_label = params.taxonomy_label?.toString()?.trim()
    if (!taxonomy_label || taxonomy_label.equalsIgnoreCase('AUTO')) {
        classifier_path_lower = classifier_file.toString().toLowerCase()
        taxonomy_label = classifier_path_lower.contains('/gg2/')   ? 'GG2'   :
                         classifier_path_lower.contains('/silva/') ? 'SILVA' :
                         classifier_path_lower.contains('/gtdb')   ? 'GTDB'  :
                         classifier_file.baseName
    }
    taxonomy_label = taxonomy_label.replaceAll(/[^A-Za-z0-9._-]/, '_')
    taxonomy_label_ch = Channel.value(taxonomy_label)

    // 5. Standard DADA2, or optional parameter sweep followed by rule-based selection.
    if (params.trimm_optimal.toString().toBoolean()) {
        TRIMM_OPTIMAL_WORKFLOW(QIIME_IMPORT_WORKFLOW.out.demux, classifier_ch, taxonomy_label_ch)
        selected_table_ch = TRIMM_OPTIMAL_WORKFLOW.out.table
        selected_repseq_ch = TRIMM_OPTIMAL_WORKFLOW.out.repseq
    } else {
        QIIME_DADA2_WORKFLOW(QIIME_IMPORT_WORKFLOW.out.demux)
        selected_table_ch = QIIME_DADA2_WORKFLOW.out.table
        selected_repseq_ch = QIIME_DADA2_WORKFLOW.out.repseq
    }

    // 6. Final SILVA taxonomy assignment and taxa bar plot using the selected ASVs.
    QIIME_TAXONOMY_WORKFLOW(
        selected_repseq_ch,
        selected_table_ch,
        metadata_ch,
        classifier_ch,
        taxonomy_label_ch
    )

    // 7. MAFFT alignment, masking, FastTree and midpoint-rooted phylogeny.
    QIIME_PHYLOGENY_WORKFLOW(selected_repseq_ch)

    // 8. Optional phylogenetic alpha/beta diversity, rarefaction, PCoA and Emperor plots.
    if (params.diversity_enabled.toString().toBoolean()) {
        QIIME_DIVERSITY_WORKFLOW(
            selected_table_ch,
            QIIME_PHYLOGENY_WORKFLOW.out.rooted_tree,
            metadata_ch
        )
    }
}
