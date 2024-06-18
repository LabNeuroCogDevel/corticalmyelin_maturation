#A script to create a df with all participants' cortex pve measures 

from pathlib import Path
import pandas as pd

print("Creating a surfstats parquet for all atlases")
dataframes = []
for tsv in Path('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/cortexpve_metrics').rglob('*regionsurfacestats.tsv'):
    dataframes.append(pd.read_csv(tsv, sep="\t"))
group_surfacestats = pd.concat(dataframes, ignore_index=True, axis=0)
group_surfacestats.to_parquet('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/surface_metrics/7T_BrainMechanisms_cortexpve.parquet')
