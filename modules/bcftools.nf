process BCFTOOLS_MPILEUP {
    tag "MPILEUP on ${reference} chunk ${chunk_index}"
    label 'process_high'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'https://depot.galaxyproject.org/singularity/bcftools:1.21--h8b25389_0':
    'quay.io/biocontainers/bcftools:1.21--h8b25389_0' }"

    input:
    tuple val(reference), path(bams), path(bais), path(ref), val(chunk_index)
    
    output:
    tuple val(reference), path("${params.project}_${reference}_chunk${chunk_index}.vcf.gz"), path("${params.project}_${reference}_chunk${chunk_index}.vcf.gz.csi"), emit: vcf
    tuple val(reference), path("${params.project}_${reference}_chunk${chunk_index}.filtered.vcf.gz"), path("${params.project}_${reference}_chunk${chunk_index}.filtered.vcf.gz.csi"), emit: filtered_vcf
    
    script:
    """
    # Increase the file descriptor limit
    ulimit -n 8192 || ulimit -Sn \$(ulimit -Hn) || true

    # Write BAM files to a list to avoid "Argument list too long" errors
    ls *.bam > bam_list.txt

    bcftools mpileup -a AD,DP,INFO/AD \
        -B -q 20 -Q 20 \
        -f ${ref} \
        -b bam_list.txt \
        | bcftools call -v -m \
        | bcftools sort -O z -o ${params.project}_${reference}_chunk${chunk_index}.vcf.gz
    
    bcftools index ${params.project}_${reference}_chunk${chunk_index}.vcf.gz
    
    bcftools view --exclude-types indels ${params.project}_${reference}_chunk${chunk_index}.vcf.gz \
        | bcftools +setGT - -- -t q -i 'FORMAT/DP<5 || QUAL<20' -n . \
        | bcftools sort -O z -o ${params.project}_${reference}_chunk${chunk_index}.filtered.vcf.gz

    bcftools index ${params.project}_${reference}_chunk${chunk_index}.filtered.vcf.gz
    """
}

process BCFTOOLS_MERGE {
    tag "Merge VCFs for ${reference}"
    label 'process_medium'
    container 'quay.io/biocontainers/bcftools:1.21--h8b25389_0'
    publishDir "${params.outdir}/${params.project}/variants", mode: 'copy'

    input:
    tuple val(reference), path(vcfs), path(vcf_csis), path(filtered_vcfs), path(filtered_vcf_csis)

    output:
    tuple val(reference), path("${params.project}_${reference}.vcf"), emit: vcf
    tuple val(reference), path("${params.project}_${reference}.filtered.vcf"), emit: filtered_vcf

    script:
    """
    NUM_VCFS=\$(echo "${vcfs}" | wc -w)
    if [ "\$NUM_VCFS" -eq 1 ]; then
        bcftools merge --force-single ${vcfs} -o ${params.project}_${reference}.vcf
        bcftools merge --force-single ${filtered_vcfs} -o ${params.project}_${reference}.filtered.vcf
    else
        bcftools merge ${vcfs} -o ${params.project}_${reference}.vcf
        bcftools merge ${filtered_vcfs} -o ${params.project}_${reference}.filtered.vcf
    fi
    """
}
