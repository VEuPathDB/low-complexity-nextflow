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
  dustmaker(seqs) | interval2bed | collectFile(storeDir: params.outputDir, name: params.outputFileName)
}

process dustmaker {
  container = 'veupathdb/blastsimilarity'

  input:
  path subsetFasta

  output:
  path "dust.out"

  script:
  """
  dustmasker -in $subsetFasta -outfmt acclist -out dust.out
  """
}

process interval2bed {
  container = 'bioperl/bioperl:stable'

  input:
  path dust

  output:
  path "dust.bed"

  script:
  """
  interval2bed.pl $dust dust.bed
  """


}
