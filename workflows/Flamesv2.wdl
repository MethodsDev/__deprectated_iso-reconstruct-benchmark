version 1.0

task Flamesv2Task {
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
        String docker = "us-central1-docker.pkg.dev/methods-dev-lab/iso-reconstruct-benchmark/flames-v2@sha256:4f5cbb9efb2a8218224cd10df003c6281d62001025792b825539b0b73088dd82"
        File monitoringScript = "gs://ctat_genome_libs/terra_scripts/cromwell_monitoring_script2.sh"
    }

    String flamesv2OutDir = "flamesv2_out"


    command <<<
        bash ~{monitoringScript} > monitoring.log &


        mkdir ~{flamesv2OutDir}

        Rscript -<< "EOF"
        library(FLAMES)
        genome_fa <- "~{referenceGenome}"
        annotation <- "~{referenceAnnotation}"
        outdir <- ~{flamesv2OutDir}
        config_file <- FLAMES::create_config(outdir)
        config <- jsonlite::fromJSON(config_file)
        find_isoform(annotation = annotation, genome_fa = genome_fa, genome_bam = genome_bam, outdir = outdir, config = config)
        EOF

    >>>

    output {
        File flamesv2GFF = "~{flamesv2OutDir}/isoform_annotated.filtered.gff3"
        File monitoringLog = "~{flamesv2OutDir}/monitoring.log"
    }

    runtime {
        cpu: cpu
        memory: "~{memoryGB} GiB"
        disks: "local-disk ~{diskSizeGB} HDD"
        docker: docker
    }
}

workflow Flamesv2 {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File referenceAnnotation
        String datasetName
    }

    call Flamesv2Task {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName
    }

    output {
        File flamesv2GFF = Flamesv2Task.flamesv2GFF
        File monitoringLog = Flamesv2Task.monitoringLog
    }
}
