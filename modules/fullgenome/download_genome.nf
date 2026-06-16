process DOWNLOAD_AND_INDEX_GENOME {
    tag "Download and index Otsh_v1.0 genome"
    label 'process_high'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:bd996097b6dd518cf788ddd6c586fb23d039cb9c-0':
        'quay.io/biocontainers/mulled-v2-fe8faa35dbf6dc65a0f7f5d4ea12e31a79f73e40:bd996097b6dd518cf788ddd6c586fb23d039cb9c-0' }"

    storeDir "${params.genome_cache}/Otsh_v1.0"

    output:
    path "Otsh_v1.0.fna", emit: genome
    path "Otsh_v1.0.fna.fai", emit: fai
    path "Otsh_v1.0.fna.{amb,ann,bwt,pac,sa}", emit: indices

    script:
    """
    wget -O Otsh_v1.0.fna.gz "${params.genome_url}"
    gunzip Otsh_v1.0.fna.gz
    bwa index Otsh_v1.0.fna
    samtools faidx Otsh_v1.0.fna
    """
}
