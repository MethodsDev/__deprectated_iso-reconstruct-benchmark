version 1.0

task MandalorionTask {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File? referenceAnnotation
        String datasetName
        Int cpu = 16
        Int numThreads = 32
        Int memoryGB = 128
        Int diskSizeGB = 500
        String docker = "us-central1-docker.pkg.dev/methods-dev-lab/iso-reconstruct-benchmark/mandalorion@sha256:c406d92b096991e1d8d00e63c30ab57213cb90f8b9a11e4ae3abd71eadb272df"
        File monitoringScript = "gs://ctat_genome_libs/terra_scripts/cromwell_monitoring_script2.sh"
    }

    String outputPrefix = if defined(referenceAnnotation) then "Mandalorion_out_~{datasetName}" else "Mandalorion_denovo_out_~{datasetName}"

    command <<<
        bash ~{monitoringScript} > monitoring.log &

        samtools bam2fq ~{inputBAM} > samtools.bam2fq.fastq
        /usr/local/src/Mandalorion/minimap2/minimap2 -ax splice --splice-flank=no -t ~{numThreads} --cs=long -uf -C5 ~{referenceGenome} samtools.bam2fq.fastq > samtools.view.sam

        samtools view -h -o samtools.view.sam ~{inputBAM}

        /usr/local/src/Mandalorion/Mando.py \
        -G ~{referenceGenome} \
        -g ~{referenceAnnotation} \
        -f samtools.bam2fq.fastq \
        -p ~{outputPrefix} \
        -s samtools.view.sam

        rm samtools.bam2fq.fastq
        rm samtools.view.sam

    >>>

    output {
        File MandalorionGTF = "~{outputPrefix}/Isoforms.filtered.clean.gtf"
        File monitoringLog = "monitoring.log"
    }

    runtime {
        cpu: cpu
        memory: "~{memoryGB} GiB"
        disks: "local-disk ~{diskSizeGB} HDD"
        docker: docker
    }
}

workflow Mandalorion {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File? referenceAnnotation
        String datasetName
    }

    call MandalorionTask {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName,
    }

    output {
        File MandalorionGTF = MandalorionTask.MandalorionGTF
        File monitoringLog = MandalorionTask.monitoringLog
    }
}
