#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//--------------------------------------------------------------------------
// Param Checking
//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
// Main Workflow
//--------------------------------------------------------------------------

workflow {
  if(!params.fastaSubsetSize) {
    error "Missing params.fastaSubsetSize"
  }

  if(!params.seqType) {
    error "Missing params.seqType"
  }

  if(params.inputFilePath) {
    seqs = channel.fromPath( params.inputFilePath )
             .splitFasta( by:params.fastaSubsetSize, file:true  )
  }
  else {
    error "Missing params.inputFilePath"
  }

  program = params.seqType == "aa"? "seg" : "dust";
  results = masker(seqs, program)
  bedFiles = interval2bed(results, program)
  indexed = indexResults(bedFiles.collectFile(), params.outputFileName)
}

process masker {
  container 'veupathdb/blastsimilarity:1.0.0'

  input:
  path subsetFasta
  val program

  output:
  path "${program}.out"

  script:
  """
  ${program}masker -in $subsetFasta -outfmt interval -out ${program}.out
  """
}

process interval2bed {
  container 'bioperl/bioperl:stable'

  input:
  path inpath
  val program

  output:
  path "${program}.bed"

  script:
  """
  interval2bed.pl $inpath ${program}.bed
  """
}

process indexResults {
  container 'biocontainers/tabix:v1.9-11-deb_cv1'

  publishDir params.outputDir, mode: 'copy'

  input:
    path bed
    val outputFileName

  output:
    path '*.bed.gz'
    path '*.gz.tbi'

  script:
  """
  sort -k1,1 -k2,2n $bed > ${outputFileName}
  bgzip ${outputFileName}
  tabix -p bed ${outputFileName}.gz
  """
}
