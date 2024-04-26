task BambuTask {
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
        Int memoryGB = 256
        Int diskSizeGB = 500
        String docker = "us-central1-docker.pkg.dev/methods-dev-lab/iso-reconstruct-benchmark/bambu@sha256:a313fb49374fca63a180e9260426011adb7dd76a2641b70acdf85f8be05c7777"
        File monitoringScript = "gs://ctat_genome_libs/terra_scripts/cromwell_monitoring_script2.sh"
    }

    String bambuOutDir = "Bambu_out"

    command <<<
        bash ~{monitoringScript} > monitoring.log &

        mkdir ~{bambuOutDir}

        if [ "~{referenceAnnotation}" != "" ]; then
            Rscript -<< "EOF"
            library(bambu)
            fa.file <- "~{referenceGenome}"
            gtf.file <- "~{referenceAnnotation}"
            bambuAnnotations <- prepareAnnotations(gtf.file)
            lr.bam <- "~{inputBAM}"
            lr.se <- bambu(reads = lr.bam, rcOutDir = "~{bambuOutDir}", annotations = bambuAnnotations, genome = fa.file, ncore = ~{numThreads})
            writeBambuOutput(lr.se, path = "~{bambuOutDir}")
            EOF

            awk ' $3 >= 1 ' ~{bambuOutDir}/counts_transcript.txt | sort -k3,3n > ~{bambuOutDir}/expressed_annotations.gtf.counts
            cut -f1 ~{bambuOutDir}/expressed_annotations.gtf.counts > ~{bambuOutDir}/expressed_transcripts.txt
            grep -Ff ~{bambuOutDir}/expressed_transcripts.txt ~{bambuOutDir}/extended_annotations.gtf > ~{bambuOutDir}/bambu.gtf
            find ~{bambuOutDir} -type f ! -name 'bambu.gtf' -delete


            Rscript -<< "EOF"
            library(bambu)
            fa.file <- "~{referenceGenome}"
            gtf.file <- "~{referenceAnnotation}"
            bambuAnnotations <- prepareAnnotations(gtf.file)
            lr.bam <- "~{inputBAM}"
            lr.se <- bambu(reads = lr.bam, rcOutDir = "~{bambuOutDir}", annotations = bambuAnnotations, genome = fa.file, ncore = ~{numThreads}, NDR = 1)
            writeBambuOutput(lr.se, path = "~{bambuOutDir}")
            EOF

            awk ' $3 >= 1 ' ~{bambuOutDir}/counts_transcript.txt | sort -k3,3n > ~{bambuOutDir}/expressed_annotations.gtf.counts
            cut -f1 ~{bambuOutDir}/expressed_annotations.gtf.counts > ~{bambuOutDir}/expressed_transcripts.txt
            grep -Ff ~{bambuOutDir}/expressed_transcripts.txt ~{bambuOutDir}/extended_annotations.gtf > ~{bambuOutDir}/bambu_ndr1.gtf


        else
            Rscript -<< "EOF"
            library(bambu)
            fa.file <- "~{referenceGenome}"
            lr.bam <- "~{inputBAM}"
            lr.se <- bambu(reads = lr.bam, rcOutDir = '~{bambuOutDir}', annotations = NULL, genome = fa.file, quant = FALSE, NDR = 1, ncore = ~{numThreads})
            writeToGTF(lr.se, path = "~{bambuOutDir}/bambu.gtf")
            EOF
        fi
    >>>

    output {
        File bambuGTF = "~{bambuOutDir}/bambu.gtf"
        File monitoringLog = "monitoring.log"
    }

    runtime {
        cpu: cpu
        memory: "~{memoryGB} GiB"
        disks: "local-disk ~{diskSizeGB} HDD"
        docker: docker
    }
}
