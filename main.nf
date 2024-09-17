#!/usr/bin/env nextflow

nextflow.enable.dsl = 2 // Enable Nextflow DSL2 

// Include modules
include { CHOPPER } from './modules/chopper/main'
include { NANOPLOT } from './modules/nanoplot/main'
include { MULTIQC } from './modules/multiqc/main'

// Include subworkflows
include { QCFASTQ_NANOPLOT } from './subworkflows/nf-core/qcfastq_nanoplot'

// Include workflows
include { AMRNANOPRO } from './workflows/amrnanopro.nf'
// Define the parameters 



workflow {
    AMRNANOPRO(params.input_fastq, params.skip_chopper)
}
