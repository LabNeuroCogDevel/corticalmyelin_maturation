#!/bin/bash

#A script to dcm2niix convert 7T Brain Mechanisms dicoms to BIDs-style organization 

input_dicomdir=/Volumes/Hera/Projects/7TBrainMech/BIDS/rawlinks
bidscompliant_dicomdir=/Volumes/Hera/Projects/corticalmyelin_development/Dicoms
bids_dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS
logs_dir=/Volumes/Hera/Projects/corticalmyelin_development/logs/BIDS

cd $input_dicomdir
for sub in 1* ; do
	subject=${sub%_*}
	session=${sub#*_}
	if ! [ -d $bids_dir/sub-$subject/ses-$session ] ; then
	heudiconv -d $bidscompliant_dicomdir/{subject}/{session}/*/* -s $subject -ss $session -f /Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/BIDS/BIDS_heudiconv/7TBrainMech_MP2RAGE_heuristic.py -c dcm2niix -b -o $bids_dir --grouping custom &> $logs_dir/${subject}_${session}-log.txt
	fi
done
