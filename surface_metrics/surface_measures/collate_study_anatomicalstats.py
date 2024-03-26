#A script to create a df with all participants' surface metrics for all atlases and specific atlases of interest 

from pathlib import Path
import pandas as pd

print("Creating a surfstats parquet for all atlases")
dataframes = []
for tsv in Path('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics').rglob('*regionsurfacestats.tsv'):
    dataframes.append(pd.read_csv(tsv, sep="\t"))
group_surfacestats = pd.concat(dataframes, ignore_index=True, axis=0)
group_surfacestats.to_parquet('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/7T_BrainMechanisms_surfacestats_allatlases.parquet')

atlases = ['aparc','glasser','gordon333dil', 'Juelich', 'Schaefer2018_400Parcels_17Networks_order', 'Schaefer2018_200Parcels_17Networks_order']

for this_atlas in atlases:
    print("Creating a surfstats parquet for " + this_atlas)
    atlas_dfs = []
    for tsv in Path('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics').rglob('*regionsurfacestats.tsv'):
        _this_df = pd.read_csv(tsv, sep="\t")
        atlas_dfs.append(_this_df[_this_df["atlas"] == this_atlas])
    atlas_df = pd.concat(atlas_dfs, ignore_index=True, axis=0)
    atlas_df.to_parquet('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/7T_BrainMechanisms_surfacestats_{0}.parquet'.format(this_atlas))

print('Creating whole-brain measures parquet')
dataframes = []
for tsv in Path('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics').rglob('*brainmeasures.tsv'):
    dataframes.append(pd.read_csv(tsv, sep="\t"))
group_brainstats = pd.concat(dataframes, ignore_index=True, axis=0)
group_brainstats.to_parquet('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/7T_BrainMechanisms_brainmeasures.parquet')
