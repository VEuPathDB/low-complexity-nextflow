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
  dustResults = dustmaker(seqs)
  bedFiles = interval2bed(dustResults)
  bedFiles.view()
  indexed = indexResults(bedFiles.collectFile())
  indexed.bed.collectFile(storeDir: params.outputDir, name: params.outputFileName)
  indexed.index.collectFile(storeDir: params.outputDir, name: params.outputFileName + ".gz.tbi")  
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

process indexResults {
  container = 'biocontainers/tabix:v1.9-11-deb_cv1'

  input:
    path bed

  output:
    path bed, emit: bed
    path 'sorted_input.bed.gz.tbi', emit: index

  script:
  """
  sort -k1,1 -k4,4n $bed > sorted_input.bed
  bgzip sorted_input.bed
  tabix -p bed sorted_input.bed.gz
  """
}