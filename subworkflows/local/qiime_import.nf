include { QIIME_IMPORT } from '../../modules/local/qiime_import'

workflow QIIME_IMPORT_WORKFLOW {
    take:
    clean_fastqs

    main:
    QIIME_IMPORT(clean_fastqs)

    emit:
    manifest = QIIME_IMPORT.out.manifest
    demux    = QIIME_IMPORT.out.demux
    summary  = QIIME_IMPORT.out.summary
}
