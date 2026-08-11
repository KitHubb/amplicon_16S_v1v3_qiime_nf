process QIIME_TAXONOMY {
    tag params.run_label
    label 'process_high'
    container params.qiime_sif

    publishDir "${params.outdir}/06_taxonomy", mode: 'copy', overwrite: true

    input:
    path repseq
    path table
    path metadata
    path classifier

    output:
    path 'taxonomy.qza',       emit: taxonomy
    path 'taxonomy.qzv',       emit: taxonomy_summary
    path 'taxa-bar-plots.qzv', emit: barplot
    path 'versions.yml',       emit: versions

    script:
    """
    export TMPDIR=\"\$PWD/tmp\" NUMBA_CACHE_DIR=\"\$PWD/numba\" MPLCONFIGDIR=\"\$PWD/mpl\" XDG_CACHE_HOME=\"\$PWD/cache\"
    mkdir -p \"\$TMPDIR\" \"\$NUMBA_CACHE_DIR\" \"\$MPLCONFIGDIR\" \"\$XDG_CACHE_HOME\"

    qiime feature-classifier classify-sklearn \
      --i-classifier ${classifier} \
      --i-reads ${repseq} \
      --p-n-jobs ${task.cpus} \
      --o-classification taxonomy.qza

    qiime metadata tabulate \
      --m-input-file taxonomy.qza \
      --o-visualization taxonomy.qzv

    qiime taxa barplot \
      --i-table ${table} \
      --i-taxonomy taxonomy.qza \
      --m-metadata-file ${metadata} \
      --o-visualization taxa-bar-plots.qzv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
      qiime2: \$(qiime --version 2>&1 | head -n 1)
    END_VERSIONS
    """
}
