include { QIIME_PHYLOGENY } from '../../modules/local/qiime_phylogeny'

workflow QIIME_PHYLOGENY_WORKFLOW {
    take:
    repseq

    main:
    QIIME_PHYLOGENY(repseq)

    emit:
    alignment        = QIIME_PHYLOGENY.out.alignment
    masked_alignment = QIIME_PHYLOGENY.out.masked_alignment
    unrooted_tree    = QIIME_PHYLOGENY.out.unrooted_tree
    rooted_tree      = QIIME_PHYLOGENY.out.rooted_tree
}
