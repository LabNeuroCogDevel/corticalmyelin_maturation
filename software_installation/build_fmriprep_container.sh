#build a singularity image for fmriprep
#docker site: https://hub.docker.com/layers/nipreps/fmriprep/23.1.4/images/sha256-e04167a435c0f49544fd01d52d927d4d1a2c85db86255489dd12c53f768a4076?context=explore
#tag: https://hub.docker.com/layers/nipreps/fmriprep/23.1.4/images/sha256-e04167a435c0f49544fd01d52d927d4d1a2c85db86255489dd12c53f768a4076?context=explore

SINGULARITY_TMPDIR=/Volumes/Hera/containers/
singularity build /Volumes/Hera/Projects/corticalmyelin_development/software/fmriprep-23.1.4.sif docker://nipreps/fmriprep:23.1.4
#This has freesurfer version: freesurfer-linux-ubuntu22_x86_64-7.3.2-20220804-6354275
