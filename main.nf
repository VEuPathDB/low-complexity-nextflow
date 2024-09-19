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
  indexed = indexResults(bedFiles.collectFile())
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

  publishDir params.outputDir, mode: 'copy', pattern: 'sorted.bed',  saveAs: {filename->params.outputFileName}
  publishDir params.outputDir, mode: 'copy', pattern: 'sorted_input.bed.gz.tbi',  saveAs: {filename->params.outputFileName+".gz.tbi"}

  input:
    path bed

  output:
    path 'sorted.bed'
    path 'sorted_input.bed.gz.tbi'

  script:
  """
  sort -k1,1 -k4,4n $bed > sorted_input.bed
  cp sorted_input.bed sorted.bed
  bgzip sorted_input.bed
  tabix -p bed sorted_input.bed.gz
  """
}