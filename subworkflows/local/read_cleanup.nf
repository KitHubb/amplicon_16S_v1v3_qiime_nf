include { CUTADAPT_V1V3 } from '../../modules/local/cutadapt_v1v3'

workflow READ_CLEANUP {
    take:
    reads

    main:
    CUTADAPT_V1V3(reads)

    emit:
    cleaned_reads = CUTADAPT_V1V3.out.reads
    json          = CUTADAPT_V1V3.out.json
    cutadapt_log  = CUTADAPT_V1V3.out.cutadapt_log
}
