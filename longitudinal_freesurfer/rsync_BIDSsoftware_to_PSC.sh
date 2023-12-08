#!/usr/bin/env bash
#
# A script to send all the files we need to the Pittsburgh super computer for running BIDS freesurfer on 7T UNIs

#Directories on rhea
BIDS_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS
software_dir=/Volumes/Hera/Projects/corticalmyelin_development/software
sample_dir=/Volumes/Hera/Projects/corticalmyelin_development/sample_info


#Directories on PSC
psc_destdir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech
psc="bridges2.psc.edu"

#Bring software and required BIDS data to the PSC
rsync --size-only -avhi --exclude CuBIDS --exclude miniconda3 --exclude Miniconda3-latest-Linux-x86_64.sh $software_dir $psc:${psc_destdir} #software containers
rsync --size-only -avhi $sample_dir $psc:${psc_destdir} #7T sample participant lists
rsync --size-only -avhi --exclude */*/anat/*acq-UNIDENT1_T1w* --exclude */*/anat/*inv* --exclude */*/anat/*UNIT1* --exclude derivatives --exclude CuBIDS --exclude .heudiconv ${BIDS_dir} $psc:${psc_destdir} #BIDS structural data
