process CUTADAPT_V1V3 {
    tag meta.id
    label 'process_medium'
    container params.cutadapt_sif

    publishDir "${params.outdir}/02_cutadapt_q20", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(r1), path(r2)

    output:
    tuple val(meta),
          path("${meta.id}.R1.trimmed.fastq.gz"),
          path("${meta.id}.R2.trimmed.fastq.gz"),
          emit: reads
    path "${meta.id}.cutadapt.json", emit: json
    path "${meta.id}.cutadapt.log",  emit: cutadapt_log
    path 'versions.yml',              emit: versions

    script:
    """
    cutadapt --cores ${task.cpus} \
      -g '${params.primer_f}' -a '${params.adapter_f}' \
      -G '${params.primer_r}' -A '${params.adapter_r}' \
      -n 2 -q ${params.quality} -Q ${params.quality} \
      --minimum-length ${params.min_length} \
      --discard-untrimmed \
      --json ${meta.id}.cutadapt.json \
      -o ${meta.id}.R1.trimmed.fastq.gz \
      -p ${meta.id}.R2.trimmed.fastq.gz \
      ${r1} ${r2} > ${meta.id}.cutadapt.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
      cutadapt: \$(cutadapt --version)
    END_VERSIONS
    """
}
