#Abagen processing pipeline in python
import os
from abagen import reporting

# Set environment variable to indicate location of donor microarray expression data
os.environ['ABAGEN_DATA'] = '/Volumes/Hera/Projects/corticalmyelin_development/software/abagen/microarray'

# Specify special fsaverage5 atlas to use for regional expression calculation
atlas = ('/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage5_den-10k_desc-atlas_hemi-R.label.gii','/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsaverage5_den-10k_desc-atlas_hemi-L.label.gii')

# Generate and save out abagen report
generator = reporting.Report(atlas, probe_selection='diff_stability', lr_mirror='bidirectional', missing='centroids', norm_matched=False, tolerance=2, sample_norm='scaled_robust_sigmoid', gene_norm='scaled_robust_sigmoid', norm_structures=True, region_agg='donors', agg_metric='mean') 
report = generator.gen_report()
with open('/Volumes/Hera/Projects/corticalmyelin_development/Maps/AHBA/AHBA_geneexpression_glasser_report.txt','w') as text_file:
    text_file.write(report)
