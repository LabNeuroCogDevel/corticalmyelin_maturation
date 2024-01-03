#A script to process AHBA gene expression data using abagen https://abagen.readthedocs.io/en/stable/cli.html version 0.1.4+15.gdc4a007

project_dir=/Volumes/Hera/Projects/corticalmyelin_development
atlas_dir=${project_dir}/Maps/HCPMMP_glasseratlas

# Create left and right hemisphere HCP-MMP Glasser parcellation .label.gii files in fsaverage5 space from the dlabel.nii cifti
## separate the whole-cortex cifti dense label into hemisphere-specific giftis
wb_command -cifti-separate $project_dir/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas.dlabel.nii COLUMN -label CORTEX_LEFT $project_dir/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas_hemi-L.label.gii -label CORTEX_RIGHT $project_dir/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas_hemi-R.label.gii
## resample hemisphere-specific giftis from fslr to fsaverage5 space
for hemi in L R; do
	wb_command -label-resample $project_dir/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas_hemi-${hemi}.label.gii $project_dir/Maps/S-A_ArchetypalAxis/FSLRVertex/fs_LR-deformed_to-fsaverage.${hemi}.sphere.32k_fs_LR.surf.gii $project_dir/Maps/S-A_ArchetypalAxis/FSaverage5/fsaverage5_std_sphere.${hemi}.10k_fsavg_${hemi}.surf.gii ADAP_BARY_AREA $project_dir/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage5_den-10k_desc-atlas_hemi-${hemi}.label.gii -area-metrics $project_dir/Maps/S-A_ArchetypalAxis/FSLRVertex/fs_LR.${hemi}.midthickness_va_avg.32k_fs_LR.shape.gii $project_dir/Maps/S-A_ArchetypalAxis/FSaverage5/fsaverage5.${hemi}.midthickness_va_avg.10k_fsavg_${hemi}.shape.gii
done

# Set up abagen analysis parameters
runargs=(
	--verbose #verbose, turn on python parseltongue
	--data-dir ${project_dir}/software/abagen/microarray #download donor expression data to here
	--n-proc 6 #use one processor per donor to download the AHBA data
        --probe-selection diff_stability #use the default probe selection method (differential stability); when multiples probes are available for a give gene, choose the probe with the most similar spatial patterns of expression across the 6 donors
	--lr_mirror bidirectional #mirror microarray expression samples across hemispheres to increase likelihood of mapping to regions
	--missing centroids #if there are regions where all donors are missing data (based on the specified tolerance), this approach will assign expression values of the tissue samples falling closest to the centroid of that region for each donor, and use a weighted average (inverse distance) of matches samples across donors 
         --norm-all #normalizing across matched samples only should be set to false (i.e., the norm-all flag should be turned on) when using missing so that the full range of samples can be surveyed for filling in missing parcels, not just samples that were already matched to regions	
	--tolerance 2 #use the default tolerance of 2 standard deviations for matching tissue samples to regions; if samples are greater than 2 SDs away from the mean matched distance they are ignored
	--sample-norm scaled_robust_sigmoid #method to use for within-sample, across-gene normalization for each donor and sample
	--gene-norm scaled_robust_sigmoid #method to use to normalize gene-specific expression values across all samples within a donor 
	--norm_structures #perform gene-norm only within structural classes (here, cortex by hemi) rather than across cortex, subcortex, and cerebellum
	--region-agg donors #use default (donors, not samples) option for averaging (agg-metric = mean) samples within a region. 'donors' averages expression values for all samples within a donor prior to averaging across-donors. (samples would combine across all samples regardless of donor and may bias to the donor with more samples in that region)
	--agg-metric mean
	--output-file ${project_dir}/Maps/AHBA/AHBA_geneexpression_glasser.csv #path where the region x gene matrix will be written
)

# Run command line abagen to process AHBA data and generate gene x region matrices
abagen "${runargs[@]}" ${atlas_dir}/glasser_space-fsaverage5_den-10k_desc-atlas_hemi-R.label.gii ${atlas_dir}/glasser_space-fsaverage5_den-10k_desc-atlas_hemi-L.label.gii

# Call abagen via python to generate and save out a report using the parameters specified above
python generate_abagen_report.py
