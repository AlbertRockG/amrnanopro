/*
 * Quality Checking with NanoPlot and Filtering with Chopper
 *
 * author: @AlbertRockG
 */

/*
 * Validate input parameters
 */

if (!params.input_fastq) {
    error "Parameter 'input_fastq' is required but not provided."
}
include { NANOPLOT as NANOPLOT_BEFORE_CHOPPER } from '../modules/nanoplot/main'  //addParams( options: params.nanoplot_fastq_options )
include { CHOPPER  } from '../modules/chopper/main'
include { NANOPLOT as NANOPLOT_AFTER_CHOPPER } from '../modules/nanoplot/main'  //addParams( options: params.nanoplot_fastq_options )
include { NANOPLOT as NANOPLOT_WITHOUT_CHOPPER } from '../modules/nanoplot/main'  //addParams( options: params.nanoplot_fastq_options )
include { MULTIQC as MULTIQC_BEFORE_CHOPPER} from '../modules/multiqc/main'
include { MULTIQC as MULTIQC_AFTER_CHOPPER} from '../modules/multiqc/main'
include { MULTIQC as MULTIQC_WITHOUT_CHOPPER} from '../modules/multiqc/main'


workflow AMRNANOPRO {
    take:
    ch_fastq
    skip_chopper

    main:
    ch_fastq = Channel
                    .fromPath(params.input_fastq, checkIfExists: true)
                    .map { it -> tuple(file(it).getBaseName(it.name.endsWith('.gz')? 2: 1), file(it))
                    }

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
        ch_trimmed_reads     = ch_fastq
    }
    
    /*
     * Emit results
     */
    emit:
    nanoplot_png_pre     // Before Chopper
    nanoplot_html_pre
    nanoplot_txt_pre
    nanoplot_log_pre
    nanoplot_version_pre
    ch_trimmed_reads     // Filtered reads from Chopper
    chopper_version
    nanoplot_png_post    // After Chopper
    nanoplot_html_post
    nanoplot_txt_post
    nanoplot_log_post
    nanoplot_version_post
}
