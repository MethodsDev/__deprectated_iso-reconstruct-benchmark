version 1.0

task IsoSeqv2Task {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        String datasetName
        Int cpu = 16
        Int numThreads = 32
        Int memoryGB = 256
        Int diskSizeGB = 500
        String docker = "us-central1-docker.pkg.dev/methods-dev-lab/iso-reconstruct-benchmark/isoseqv2@sha256:6d19ef75f9da96a76b9db24f6191369e17765693da297a06f775b55c23c36393"
        File monitoringScript = "gs://ctat_genome_libs/terra_scripts/cromwell_monitoring_script2.sh"
    }

    command <<<
        bash ~{monitoringScript} > monitoring.log &

        samtools fastq ~{inputBAM} > temp.fastq

        pbmm2 align --num-threads ~{numThreads} --preset ISOSEQ --sort ~{referenceGenome} temp.fastq  pbmm_realigned.bam

        isoseq3 collapse pbmm_realigned.bam "IsoSeqv2_out_~{datasetName}.gff"
    >>>

    output {
        File isoSeqv2GFF = "IsoSeqv2_out_~{datasetName}.gff"
        File monitoringLog = "monitoring.log"
    }

    runtime {
        cpu: cpu
        memory: "~{memoryGB} GiB"
        disks: "local-disk ~{diskSizeGB} HDD"
        docker: docker
    }
}

workflow IsoSeqv2 {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        String datasetName
    }

    call IsoSeqv2Task {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            datasetName = datasetName
    }

    output {
        File isoSeqv2GFF = IsoSeqv2Task.isoSeqv2GFF
        File monitoringLog = IsoSeqv2Task.monitoringLog
    }
}
