#!/usr/bin/env bash

#A script to send R1 volumetric maps to the Pittsburgh super computer for surface-based R1 analysis 

#Directories on rhea
R1dir=/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/R1maps

#Directories on PSC
psc_destdir=/ocean/projects/soc230004p/shared/datasets/7TBrainMech/BIDS/derivatives/R1maps
psc="bridges2.psc.edu"

#Bring R1 data to the PSC
rsync --size-only -avhi ${R1dir} $psc:${psc_destdirdd}
