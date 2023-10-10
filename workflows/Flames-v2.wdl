version 1.0

task FlamesTask {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File referenceAnnotation
        String datasetName
        Int cpu = 16
        Int memoryGB = 256
        Int diskSizeGB = 500
        String docker = "us.gcr.io/broad-dsde-methods/kockan/flames@sha256:e9b5d5152179e1a820afde3b147586a8ce7440738bf456af74b22ca4cfa0e8cb"
        File monitoringScript = "gs://ctat_genome_libs/terra_scripts/cromwell_monitoring_script2.sh"
    }

    String flamesOutDir = "flames_out"


    command <<<
        bash ~{monitoringScript} > monitoring.log &


        mkdir ~{flamesOutDir}

        Rscript -<< "EOF"
        library(FLAMES)
        genome_fa <- "~{referenceGenome}"
        annotation <- "~{referenceAnnotation}"
        outdir <- ~{flamesOutDir}
        config_file <- FLAMES::create_config(outdir)
        config <- jsonlite::fromJSON(config_file)
        find_isoform(annotation = annotation, genome_fa = genome_fa, genome_bam = genome_bam, outdir = outdir, config = config)
        EOF

    >>>

    output {
        File flamesGFF = "~{flamesOutDir}/isoform_annotated.filtered.gff3"
        File monitoringLog = "~{flamesOutDir}/monitoring.log"
    }

    runtime {
        cpu: cpu
        memory: "~{memoryGB} GiB"
        disks: "local-disk ~{diskSizeGB} HDD"
        docker: docker
    }
}

workflow Flames {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File referenceAnnotation
        String datasetName
    }

    call FlamesTask {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName
    }

    output {
        File flamesGFF = FlamesTask.flamesGFF
        File monitoringLog = FlamesTask.monitoringLog
    }
}
