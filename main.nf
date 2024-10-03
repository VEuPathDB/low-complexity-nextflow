#!/usr/bin/env nextflow
nextflow.enable.dsl=2

//--------------------------------------------------------------------------
// Param Checking
//--------------------------------------------------------------------------

if(!params.fastaSubsetSize) {
  throw new Exception("Missing params.fastaSubsetSize")
}

if(params.inputFilePath) {
  seqs = Channel.fromPath( params.inputFilePath )
           .splitFasta( by:params.fastaSubsetSize, file:true  )
}
else {
  throw new Exception("Missing params.inputFilePath")
}

//--------------------------------------------------------------------------
// Main Workflow
//--------------------------------------------------------------------------

workflow {
  program = params.seqType == "aa"? "seg" : "dust";
  results = masker(seqs, program)
  bedFiles = interval2bed(results, program)
  indexed = indexResults(bedFiles.collectFile(), params.outputFileName)
}

process masker {
  container = 'veupathdb/blastsimilarity'

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
  container = 'bioperl/bioperl:stable'

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
  container = 'biocontainers/tabix:v1.9-11-deb_cv1'

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
