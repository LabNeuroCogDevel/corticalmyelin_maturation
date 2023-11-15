#build a neuromaps singularity image 
#docker site: https://hub.docker.com/r/netneurolab/neuromaps/tags
#tag: https://hub.docker.com/layers/netneurolab/neuromaps/0.0.4/images/sha256-8ee299a9f221cb8d8e630ee270ee03a920c75243a8f2fc9cf787fa6b911c62d6?context=explore 

SINGULARITY_TMPDIR=/Volumes/Hera/containers/
singularity build /Volumes/Hera/Projects/corticalmyelin_development/software/neuromaps-0.0.4.sif docker://netneurolab/neuromaps:0.0.4
