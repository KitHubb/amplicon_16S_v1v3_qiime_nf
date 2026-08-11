include { QIIME_DADA2 } from '../../modules/local/qiime_dada2'

workflow QIIME_DADA2_WORKFLOW {
    take:
    demux

    main:
    QIIME_DADA2(demux)

    emit:
    table          = QIIME_DADA2.out.table
    repseq         = QIIME_DADA2.out.repseq
    stats          = QIIME_DADA2.out.stats
    stats_summary  = QIIME_DADA2.out.stats_summary
    table_summary  = QIIME_DADA2.out.table_summary
    repseq_summary = QIIME_DADA2.out.repseq_summary
}
