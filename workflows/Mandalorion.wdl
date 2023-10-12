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
        String docker = "us-central1-docker.pkg.dev/methods-dev-lab/iso-reconstruct-benchmark/mandalorion@sha256:9a2dd74d2a716ed59784b75f64ddf43e451e59e0afb31dfe40176eed4a2460cf"
        File monitoringScript = "gs://ctat_genome_libs/terra_scripts/cromwell_monitoring_script2.sh"
    }


    command <<<
        bash ~{monitoringScript} > monitoring.log &

        samtools bam2fq ~{inputBAM} > samtools.bam2fq.fastq
        samtools view -h -o samtools.view.sam ~{inputBAM}

        /usr/local/src/Mandalorion/Mando.py \
        -G ~{referenceGenome} \
        ~{"g" + referenceAnnotation} \
        -f samtools.bam2fq.fastq \
        -p ~{datasetName} \
        -s samtools.view.sam

        rm samtools.bam2fq.fastq
        rm samtools.view.sam

    >>>

    output {
        File MandalorionGTF = "~{datasetName}/Isoforms.filtered.clean.gtf"
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
        File referenceAnnotation
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
