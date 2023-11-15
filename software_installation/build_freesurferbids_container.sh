#build a singularity image to run the freesurfer BIDS app with
#bids-apps/freesurfer: https://github.com/bids-apps/freesurfer
#docker site: https://hub.docker.com/r/bids/freesurfer/tags
#tag: https://hub.docker.com/layers/bids/freesurfer/7.4.1-202309/images/sha256-720b4365f2bc4c4b787d6a80606a2dc06e5ef88f44f55c06131e829845f3b433?context=explore
#freesurfer version: freesurfer-linux-centos7_x86_64-7.4.1-20230613-7eb8460 

SINGULARITY_TMPDIR=/Volumes/Hera/containers/
singularity build /Volumes/Hera/Projects/corticalmyelin_developent/software/freesurfer-7.4.1/sif docker://bids/freesurfer:7.4.1-202309
