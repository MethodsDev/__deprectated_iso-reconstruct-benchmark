version 1.0

task Flames-v2Task {
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

    String flames-v2OutDir = "flames-v2_out"


    command <<<
        bash ~{monitoringScript} > monitoring.log &


        mkdir ~{flames-v2OutDir}

        Rscript -<< "EOF"
        library(FLAMES)
        genome_fa <- "~{referenceGenome}"
        annotation <- "~{referenceAnnotation}"
        outdir <- ~{flames-v2OutDir}
        config_file <- FLAMES::create_config(outdir)
        config <- jsonlite::fromJSON(config_file)
        find_isoform(annotation = annotation, genome_fa = genome_fa, genome_bam = genome_bam, outdir = outdir, config = config)
        EOF

    >>>

    output {
        File flames-v2GFF = "~{flames-v2OutDir}/isoform_annotated.filtered.gff3"
        File monitoringLog = "~{flames-v2OutDir}/monitoring.log"
    }

    runtime {
        cpu: cpu
        memory: "~{memoryGB} GiB"
        disks: "local-disk ~{diskSizeGB} HDD"
        docker: docker
    }
}

workflow Flames-v2 {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File referenceAnnotation
        String datasetName
    }

    call Flames-v2Task {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName
    }

    output {
        File flames-v2GFF = Flames-v2Task.flames-v2GFF
        File monitoringLog = Flames-v2Task.monitoringLog
    }
}
