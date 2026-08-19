#!/usr/bin env nextflow

nextflow.enable.dsl = 2

process CDFW_RECODE {
    tag 'Recoding genotypes to numerical alleles'
    container 'cloud.sylabs.io/library/nickmiller-cdfw/r-cmdargs/r-cmdargs:20260819'
    publishDir "${params.outdir}/${params.project}/cdfw/recoding", mode: 'copy'


    input:
        path(hap_raw_file)
        path(locus_index_file)
        path(RoSA_loci_file)
	path(rubias_loci_file)
        path(colony_loci_file)
    
    output:

        path "outputs/fish_recoded_wide_*.csv", emit: recoded_wide
        path "outputs/fish_recoded_wide_Rubias_*.csv", emit: recoded_rubias
        path "outputs/fish_recoded_wide_Colony_*.csv", emit: recoded_colony
        path "outputs/fish_recoded_wide_RoSA_only_*.csv", emit: recoded_rosa
    
    script:
        """
        mkdir outputs data tempdata
        cdfw_recoder.R ${hap_raw_file} ${locus_index_file} --RoSA ${RoSA_loci_file} --rubias ${rubias_loci_file} --colony ${colony_loci_file}
        """

}

workflow CDFW {
   take:
    unfiltered_haps
   main:
    hap_raw_file_ch = unfiltered_haps.map { it[1] }
    locus_index_file_ch = Channel.fromPath(params.cdfw_locus_index_file)
    full_panel_loci_file_ch = Channel.fromPath(params.cdfw_full_panel_loci_file)
    colony_loci_file_ch = Channel.fromPath(params.cdfw_colony_loci_file)
    

    CDFW_RECODE(hap_raw_file_ch, locus_index_file_ch, full_panel_loci_file_ch, colony_loci_file_ch, "testrun")
    
}

