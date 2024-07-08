export TEMPLATEFLOW_HOME=/Volumes/Hera/Projects/corticalmyelin_development/Maps/Templates/
python3 -c 'import templateflow.api as tf; print(tf.get("fsaverage", density="164k",suffix="white",desc=None, extension="surf.gii"))'
python3 -c 'import templateflow.api as tf; print(tf.get("fsaverage", density="164k",suffix="midthickness",desc=None, extension="surf.gii"))'
python3 -c 'import templateflow.api as tf; print(tf.get("fsaverage", density="164k",suffix="pial",desc=None, extension="surf.gii"))'
python3 -c 'import templateflow.api as tf; print(tf.get("fsLR", density="32k",suffix="midthickness",desc=None, extension="surf.gii"))'
python3 -c 'import templateflow.api as tf; print(tf.get("fsLR", density="164k",suffix="midthickness",desc=None, extension="surf.gii"))'
python3 -c 'import templateflow.api as tf; print(tf.get("MNI152NLin2009cAsym", resolution=[1,2],desc=None, suffix="T1w"))'

