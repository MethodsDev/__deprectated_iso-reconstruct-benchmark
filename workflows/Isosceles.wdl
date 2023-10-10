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


        mkdir ~{IsoscelesOutDir}

        Rscript -<< "EOF"
        library(Isosceles)

        bam_file <- ~{inputBAM}
        gtf_file <- ~{referenceAnnotation}
        genome_fasta_file <- ~{referenceGenome}
        
        bam_files <- c(Sample = bam_file)
        bam_parsed <- extract_read_structures(bam_files = bam_files)
        transcript_data <- prepare_transcripts(
            gtf_file = gtf_file,
            genome_fasta_file = genome_fasta_file,
            bam_parsed = bam_parsed,
            min_bam_splice_read_count = 2,
            min_bam_splice_fraction = 0.01
        )

        se_tcc <- prepare_tcc_se(
            bam_files = bam_files,
            transcript_data = transcript_data,
            run_mode = "de_novo_loose",
            min_read_count = 1,
            min_relative_expression = 0
        )

        se_transcript <- prepare_transcript_se(
            se_tcc = se_tcc,
            use_length_normalization = TRUE
        )

        export_gtf(se_transcript, "~{IsoscelesOutDir}/isoform_annotated.gtf")
        EOF

    >>>

    output {
        File flamesGFF = "~{IsoscelesOutDir}/isoform_annotated.gtf"
        File monitoringLog = "~{IsoscelesOutDir}/monitoring.log"
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
