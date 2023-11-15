#build a singularity image for xcp-d
#docker site: https://hub.docker.com/r/pennlinc/xcp_d/tags
#tag: https://hub.docker.com/layers/pennlinc/xcp_d/0.5.0/images/sha256-03f7d6be3040f4ba5be9c7978c3c8fef30fab2b4a36d5b6957e5a58d58b0f8ba?context=explore

SINGULARITY_TMPDIR=/Volumes/Hera/containers/
singularity build /Volumes/Hera/Projects/corticalmyelin_development/software/xcp_d-0.5.0.sif docker://pennlinc/xcp_d:0.5.0
