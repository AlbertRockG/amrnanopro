process DOWNLOAD_TEST_DATA {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gnu-wget:1.18--h36e9172_9' :
        'biocontainers/gnu-wget:1.18--h36e9172_9' }"
    
    input:
    tuple val(meta), val(url)

    output:
    tuple val(meta), path("*.fastq.gz") , emit: test_data_ch
    path "versions.yml"                 , emit: versions

    when: params.download_test_data

    script:
    """
    wget -O '${meta}'.fastq.gz  '${url}'

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(echo \$(wget --version 2>&1) | sed 's/^.*wget //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch '${meta}'.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(echo \$(wget --version 2>&1) | sed 's/^.*wget //; s/ .*\$//')
    END_VERSIONS
    """
}
