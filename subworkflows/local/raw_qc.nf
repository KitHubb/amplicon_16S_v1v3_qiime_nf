include { FASTQC as FASTQC_RAW } from '../../modules/local/fastqc'
include { MULTIQC as MULTIQC_RAW } from '../../modules/local/multiqc'

workflow RAW_QC {
    take:
    reads

    main:
    FASTQC_RAW(reads, '01_raw_qc')
    MULTIQC_RAW(FASTQC_RAW.out.zip.collect(), '01_raw_qc')

    emit:
    report = MULTIQC_RAW.out.report
}
