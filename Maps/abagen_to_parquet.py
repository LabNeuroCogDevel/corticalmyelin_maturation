import pandas as pd

df = pd.read_csv('/Volumes/Hera/Projects/corticalmyelin_development/Maps/AHBA/AHBA_geneexpression_glasser.csv')
df.to_parquet('/Volumes/Hera/Projects/corticalmyelin_development/Maps/AHBA/AHBA_geneexpression_glasser.parquet')
