#build a singularity image to run SPM12 with
#https://github.com/bids-apps/SPM
#docker site: https://hub.docker.com/r/bids/spm/tags
#tag: https://hub.docker.com/layers/bids/spm/latest/images/sha256-cb77a4589bd6a3fb4cf79c76781e8a0cd92ce045ee1373679ddc431afb2a0a16?context=explore

SINGULARITY_TMPDIR=/Volumes/Hera/containers/
SINGULARITY_CACHEDIR=/Volumes/Hera/containers
singularity build /Volumes/Hera/Projects/corticalmyelin_development/software/spm-latest.sif docker://bids/spm:latest

