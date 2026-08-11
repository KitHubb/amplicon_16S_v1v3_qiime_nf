include { QIIME_DIVERSITY } from '../../modules/local/qiime_diversity'

workflow QIIME_DIVERSITY_WORKFLOW {
    take:
    table
    rooted_tree
    metadata

    main:
    QIIME_DIVERSITY(table, rooted_tree, metadata)

    emit:
    core_metrics      = QIIME_DIVERSITY.out.core_metrics
    alpha_rarefaction = QIIME_DIVERSITY.out.alpha_rarefaction
    faith_group       = QIIME_DIVERSITY.out.faith_group
    observed_group    = QIIME_DIVERSITY.out.observed_group
    shannon_group     = QIIME_DIVERSITY.out.shannon_group
    evenness_group    = QIIME_DIVERSITY.out.evenness_group
}
