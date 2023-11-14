#!/bin/bash
#A script to organize dicoms into /Volumes/Hera/Projects/corticalmyelin_development/Dicoms following the {subject}/{session} organization

input_dicomdir=/Volumes/Hera/Projects/7TBrainMech/BIDS/rawlinks
bidscompliant_dicomdir=/Volumes/Hera/Projects/corticalmyelin_development/Dicoms

cd $input_dicomdir
for sub in 1* ; do
	subject=${sub%_*}
	session=${sub#*_}
	if ! [ -d $bidscompliant_dicomdir/$subject/$session ] ; then
		mkdir -p $bidscompliant_dicomdir/$subject/$session
		ln -s $input_dicomdir/${subject}_${session}/*B1-abs-1slc-singleChannelMode-B1* $bidscompliant_dicomdir/$subject/$session/
		ln -s $input_dicomdir/${subject}_${session}/*MP2RAGEPTX-TR6000-1mmiso-INV1_192 $bidscompliant_dicomdir/$subject/$session/
		ln -s $input_dicomdir/${subject}_${session}/*MP2RAGEPTX-TR6000-1mmiso-INV1-PHS-FILT_192 $bidscompliant_dicomdir/$subject/$session/
		ln -s $input_dicomdir/${subject}_${session}/*MP2RAGEPTX-TR6000-1mmiso-INV2_192 $bidscompliant_dicomdir/$subject/$session/
		ln -s $input_dicomdir/${subject}_${session}/*MP2RAGEPTX-TR6000-1mmiso-INV2-PHS-FILT_192 $bidscompliant_dicomdir/$subject/$session/
		ln -s $input_dicomdir/${subject}_${session}/*MP2RAGEPTX-TR6000-1mmiso-UNI-Images_192 $bidscompliant_dicomdir/$subject/$session/
		ln -s $input_dicomdir/${subject}_${session}/*_MP2RAGEPTX-TR6000-1mmiso-UNI-DEN_192 $bidscompliant_dicomdir/$subject/$session/
		ln -s $input_dicomdir/${subject}_${session}/*MP2RAGEPTX-TR6000-1mmiso-T1-Images_192 $bidscompliant_dicomdir/$subject/$session/
	fi
done
