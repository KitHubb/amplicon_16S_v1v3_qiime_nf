include { QIIME_TAXONOMY } from '../../modules/local/qiime_taxonomy'

workflow QIIME_TAXONOMY_WORKFLOW {
    take:
    repseq
    table
    metadata
    classifier

    main:
    QIIME_TAXONOMY(repseq, table, metadata, classifier)

    emit:
    taxonomy         = QIIME_TAXONOMY.out.taxonomy
    taxonomy_summary = QIIME_TAXONOMY.out.taxonomy_summary
    barplot          = QIIME_TAXONOMY.out.barplot
}
