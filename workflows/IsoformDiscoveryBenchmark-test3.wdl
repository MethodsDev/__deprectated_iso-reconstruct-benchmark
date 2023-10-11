version 1.0

import "Mandalorion.wdl" as MandalorionWorkflow
import "IsoQuantv2.wdl" as IsoQuantv2Workflow
import "StringTie.wdl" as StringTieWorkflow
import "Bambu.wdl" as BambuWorkflow
import "Flair.wdl" as FlairWorkflow
import "Talon.wdl" as TalonWorkflow
import "IsoSeqv2.wdl" as IsoSeqv2Workflow
import "Flames.wdl" as FlamesWorkflow
import "Cupcake.wdl" as CupcakeWorkflow
import "IsoformDiscoveryBenchmarkTasks.wdl" as IsoformDiscoveryBenchmarkTasks

workflow LongReadRNABenchmark {
    input {
        File inputBAM
        File inputBAMIndex
        File referenceGenome
        File referenceGenomeIndex
        File referenceAnnotation
        File expressedGTF
        File expressedKeptGTF
        File excludedGTF
        String datasetName
        String dataType
    }

    call MandalorionWorkflow.Mandalorion as Mandalorion {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName,
    }


    call IsoQuantv2Workflow.IsoQuantv2 as IsoQuantv2 {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName,
            dataType = dataType
    }

    call IsoQuantv2Workflow.IsoQuantv2 as IsoQuantv2ReferenceFree {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            datasetName = datasetName,
            dataType = dataType
    }


    call StringTieWorkflow.StringTie as StringTie {
        input:
            inputBAM = inputBAM,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName
    }

    call StringTieWorkflow.StringTie as StringTieReferenceFree {
        input:
            inputBAM = inputBAM,
            datasetName = datasetName
    }

    call BambuWorkflow.Bambu as Bambu {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName,
            dataType = dataType
    }

    call FlairWorkflow.Flair as Flair {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName
    }

    call TalonWorkflow.Talon as Talon {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName,
            dataType = dataType
    }


    call IsoSeqv2Workflow.IsoSeqv2 as IsoSeqv2 {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            datasetName = datasetName
    }


    call FlamesWorkflow.Flames as Flames {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            referenceGenome = referenceGenome,
            referenceGenomeIndex = referenceGenomeIndex,
            referenceAnnotation = referenceAnnotation,
            datasetName = datasetName
    }


    call CupcakeWorkflow.Cupcake as Cupcake {
        input:
            inputBAM = inputBAM,
            inputBAMIndex = inputBAMIndex,
            datasetName = datasetName
    }


    # Note: Make sure that your toolNames arrays match the order of your gtfList arrays.
    # If they don't match, you may not get an error but you will get incorrect results.
    Array[File] gtfListReduced = [Mandalorion.MandalorionGTF, IsoQuantv2.isoQuantv2GTF, StringTie.stringTieGTF, Bambu.bambuGTF, Flair.flairGTF, Talon.talonGTF, Flames.flamesGFF]
    Array[File] gtfListReferenceFree = [IsoQuantv2ReferenceFree.isoQuantv2GTF, StringTieReferenceFree.stringTieGTF, IsoSeqv2.isoSeqv2GFF, Cupcake.cupcakeGFF]
    Array[String] toolNamesReduced = ["mandalorion_v4.3.0", "isoquant_v3.3.0", "stringtie_v2.2.1", "bambu_v3.2.6", "flair_v2.0.0", "talon_v5.0", "flames_vpy"]
    Array[String] toolNamesReferenceFree = ["isoquant_v3.3.0", "stringtie_v2.2.1", "isoseq_v4.0.0", "cupcake_v29.0.0"]

    scatter(gtfAndTool in zip(gtfListReduced, toolNamesReduced)) {
        File gtf = gtfAndTool.left
        String tool = gtfAndTool.right

        call IsoformDiscoveryBenchmarkTasks.GffCompareTrack {
            input:
                datasetName = datasetName,
                toolName = tool,
                toolGTF = gtf,
                expressedGTF = expressedGTF,
                expressedKeptGTF = expressedKeptGTF
        }
    }

    call IsoformDiscoveryBenchmarkTasks.GffCompareTrackDenovo {
        input:
            datasetName = datasetName,
            toolGTFs = gtfListReduced,
            expressedKeptGTF = expressedKeptGTF
    }

    scatter(gtf in gtfListReferenceFree) {
        call IsoformDiscoveryBenchmarkTasks.ReferenceFreeAnalysis {
            input:
                inputGTF = gtf,
                expressedGTF = expressedGTF
        }
    }

    call IsoformDiscoveryBenchmarkTasks.SummarizeAnalysis {
        input:
            trackingFiles = GffCompareTrack.tracking,
            toolNames = toolNamesReduced,
            datasetName = datasetName
    }

    call IsoformDiscoveryBenchmarkTasks.SummarizeReferenceFreeAnalysis {
        input:
            inputList = ReferenceFreeAnalysis.stats,
            toolNames = toolNamesReferenceFree,
            datasetName = datasetName
    }


    call IsoformDiscoveryBenchmarkTasks.PlotAnalysisSummary as PlotAnalysisSummary {
        input:
            summary = SummarizeAnalysis.summary,
            datasetName = datasetName,
            type = "reduced"
    }

    call IsoformDiscoveryBenchmarkTasks.PlotAnalysisSummary as PlotAnalysisSummaryReferenceFree {
        input:
            summary = SummarizeReferenceFreeAnalysis.summary,
            datasetName = datasetName,
            type = "reffree"
    }

    output {
        File analysisSummary = SummarizeAnalysis.summary
        File analysisSummaryReferenceFree = SummarizeReferenceFreeAnalysis.summary
        File analysisSummaryPlot = PlotAnalysisSummary.analysisSummaryPlot
        File referenceFreeAnalysisSummaryPlot = PlotAnalysisSummaryReferenceFree.analysisSummaryPlot
    }
}
