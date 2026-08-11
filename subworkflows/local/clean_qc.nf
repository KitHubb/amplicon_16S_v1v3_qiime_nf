include { FASTQC as FASTQC_CLEAN } from '../../modules/local/fastqc'
include { MULTIQC as MULTIQC_CLEAN } from '../../modules/local/multiqc'

workflow CLEAN_QC {
    take:
    reads

    main:
    FASTQC_CLEAN(reads, '03_clean_qc')
    MULTIQC_CLEAN(FASTQC_CLEAN.out.zip.collect(), '03_clean_qc')

    emit:
    report = MULTIQC_CLEAN.out.report
}
