/*
 * Quality Checking with NanoPlot and Filtering with Chopper
 *
 * author: @AlbertRockG
 */

/*
 * Validate input parameters
 */

include { NANOPLOT as NANOPLOT_BEFORE_CHOPPER } from '../modules/nanoplot/main'  //addParams( options: params.nanoplot_fastq_options )
include { CHOPPER  } from '../modules/chopper/main'
include { NANOPLOT as NANOPLOT_AFTER_CHOPPER } from '../modules/nanoplot/main'  //addParams( options: params.nanoplot_fastq_options )
include { NANOPLOT as NANOPLOT_WITHOUT_CHOPPER } from '../modules/nanoplot/main'  //addParams( options: params.nanoplot_fastq_options )
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/dumpsoftwareversions/main'                                                           
include { MULTIQC } from '../modules/multiqc/main'


workflow AMRNANOPRO {
    take:
    ch_fastq
    skip_chopper

    main:
    /*
     * FastQ Quality Checking using NanoPlot before Chopper (if skip_nanoplot is false)
     */
    nanoplot_png_pre     = Channel.empty()
    nanoplot_html_pre    = Channel.empty()
    nanoplot_txt_pre     = Channel.empty()
    nanoplot_log_pre     = Channel.empty()
    nanoplot_version_pre = Channel.empty()
    chopper_version  = Channel.empty()
    nanoplot_png_post     = Channel.empty()
    nanoplot_html_post    = Channel.empty()
    nanoplot_txt_post     = Channel.empty()
    nanoplot_log_post     = Channel.empty()
    nanoplot_version_post = Channel.empty()
    ch_versions           = Channel.empty()
    ch_multiqc_report     = Channel.empty()

    /*
    * Filtering using CHOPPER (if skip_chopper is false)
    */
    if (!skip_chopper) {
        NANOPLOT_BEFORE_CHOPPER ( ch_fastq )

        nanoplot_png_pre     = NANOPLOT_BEFORE_CHOPPER.out.png
        nanoplot_html_pre    = NANOPLOT_BEFORE_CHOPPER.out.html
        nanoplot_txt_pre     = NANOPLOT_BEFORE_CHOPPER.out.txt
        nanoplot_log_pre     = NANOPLOT_BEFORE_CHOPPER.out.log
        nanoplot_version_pre = NANOPLOT_BEFORE_CHOPPER.out.versions
        ch_versions          = ch_versions.mix (nanoplot_version_pre.first().ifEmpty(null))

        CHOPPER ( ch_fastq )

        ch_trimmed_reads = CHOPPER.out.fastq
        chopper_version  = CHOPPER.out.versions
        ch_versions      = ch_versions.mix (chopper_version.first().ifEmpty(null))


        NANOPLOT_AFTER_CHOPPER ( ch_trimmed_reads )

        nanoplot_png_post     = NANOPLOT_AFTER_CHOPPER.out.png
        nanoplot_html_post    = NANOPLOT_AFTER_CHOPPER.out.html
        nanoplot_txt_post     = NANOPLOT_AFTER_CHOPPER.out.txt
        nanoplot_log_post     = NANOPLOT_AFTER_CHOPPER.out.log
        nanoplot_version_post = NANOPLOT_AFTER_CHOPPER.out.versions
        ch_versions           = ch_versions.mix (nanoplot_version_post.first().ifEmpty(null))

        
    } else {

        NANOPLOT_WITHOUT_CHOPPER ( ch_fastq )

        nanoplot_png_pre     = NANOPLOT_WITHOUT_CHOPPER.out.png
        nanoplot_html_pre    = NANOPLOT_WITHOUT_CHOPPER.out.html
        nanoplot_txt_pre     = NANOPLOT_WITHOUT_CHOPPER.out.txt
        nanoplot_log_pre     = NANOPLOT_WITHOUT_CHOPPER.out.log
        nanoplot_version_pre = NANOPLOT_WITHOUT_CHOPPER.out.versions
        ch_versions          = ch_versions.mix (nanoplot_version_pre.first().ifEmpty(null))
        ch_trimmed_reads     = ch_fastq
    }

    //
    // SOFTWARE_VERSIONS
    //
    

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name:'collated_versions.yml')
    )


//
    // MODULE: MULTIQC
    //

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(nanoplot_txt_pre.collect{it[1]})


    if (!skip_chopper) {
        ch_multiqc_files = ch_multiqc_files.mix(nanoplot_txt_post.collect{it[1]})    
        }

    MULTIQC ( ch_multiqc_files.collect() )
    ch_multiqc_report = MULTIQC.out.report
    ch_versions = ch_versions.mix(MULTIQC.out.versions)
    
    /*
     * Emit results
     */
    emit:
    nanoplot_png_pre     // Before Chopper
    nanoplot_html_pre
    nanoplot_txt_pre
    nanoplot_log_pre
    ch_trimmed_reads     // Filtered reads from Chopper
    nanoplot_png_post    // After Chopper
    nanoplot_html_post
    nanoplot_txt_post
    nanoplot_log_post
    multiqc_report = ch_multiqc_report.toList()
    versions = ch_versions
}
