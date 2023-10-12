version 1.0

task IsoQuantv2Task {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File? referenceAnnotation
        String datasetName
        String dataType
        Int cpu = 16
        Int numThreads = 32
        Int memoryGB = 128
        Int diskSizeGB = 500
        String docker = "us-central1-docker.pkg.dev/methods-dev-lab/iso-reconstruct-benchmark/isoquant-v2@sha256:54d44e7ee5215d9a2dfcc985dad6fc15180f3cb29cf65568dcac8e8aeb087968"
        File monitoringScript = "gs://ctat_genome_libs/terra_scripts/cromwell_monitoring_script2.sh"
    }

    String outputPrefix = if defined(referenceAnnotation) then "IsoQuantv2_out_~{datasetName}" else "IsoQuantv2_denovo_out_~{datasetName}"
    String completeGeneDBOption = if defined(referenceAnnotation) then "--complete_genedb" else ""
    
    command <<<
        bash ~{monitoringScript} > monitoring.log &

        /usr/local/src/IsoQuant/isoquant.py \
        --reference ~{referenceGenome} \
        ~{completeGeneDBOption} \
        ~{"--genedb " + referenceAnnotation} \
        --bam ~{inputBAM} \
        --data_type ~{dataType} \
        --threads ~{numThreads} \
        --prefix ~{datasetName} \
        --output ~{outputPrefix}
    >>>

    output {
        File isoQuantv2GTF = "~{outputPrefix}/~{datasetName}/~{datasetName}.transcript_models.gtf"
        File monitoringLog = "monitoring.log"
    }

    runtime {
        cpu: cpu
        memory: "~{memoryGB} GiB"
        disks: "local-disk ~{diskSizeGB} HDD"
        docker: docker
    }
}

workflow IsoQuantv2 {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File? referenceAnnotation
        String datasetName
        String dataType
    }

    call IsoQuantv2Task {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName,
            dataType = dataType
    }

    output {
        File isoQuantv2GTF = IsoQuantv2Task.isoQuantv2GTF
        File monitoringLog = IsoQuantv2Task.monitoringLog
    }
}
