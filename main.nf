#!/usr/bin/env nextflow

nextflow.enable.dsl = 2 // Enable Nextflow DSL2 

// Include modules
include { DOWNLOAD_TEST_DATA } from './modules/download_test_data/main'
include { CHOPPER } from './modules/chopper/main'
include { NANOPLOT } from './modules/nanoplot/main'
include { MULTIQC } from './modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/dumpsoftwareversions/main'                                                           


// Include workflows
include { AMRNANOPRO } from './workflows/amrnanopro.nf'




workflow {
    if (params.download_test_data) {
        url_ch = Channel
                            .of(params.test_data_url)
                            .map { it -> tuple(file(it).getBaseName(it.endsWith('.gz')? 2: 1), it) 
                            }

        DOWNLOAD_TEST_DATA(url_ch)
        input_ch = DOWNLOAD_TEST_DATA.out.test_data_ch.view()
    } else if (params.input_fastq) {
        input_ch = Channel
                        .fromPath(params.input_fastq, checkIfExists: true)
                        .map { it -> tuple(file(it).getBaseName(it.name.endsWith('.gz')? 2: 1), file(it))
                        }
    }

    AMRNANOPRO(input_ch, params.skip_chopper)
}
