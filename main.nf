#!/usr/bin/env nextflow

nextflow.enable.dsl = 2 // Enable Nextflow DSL2 

// Include modules
include { CHOPPER } from './modules/chopper/main'
include { NANOPLOT } from './modules/nanoplot/main'
include { MULTIQC } from './modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './modules/dumpsoftwareversions/main'                                                           

// Include subworkflows

// Include workflows
include { AMRNANOPRO } from './workflows/amrnanopro.nf'
// Define the parameters 



workflow {
    AMRNANOPRO(params.input_fastq, params.skip_chopper)
}
