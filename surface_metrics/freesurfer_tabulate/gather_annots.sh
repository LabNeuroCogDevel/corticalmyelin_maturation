#!/bin/bash

datalad run \
  --explicit \
  --expand outputs \
  -m "Download and create some annots" \
  -o "gather_annot_files.html" \
  -o 'annots/*.annot' \
  "jupyter nbconvert --to html --execute gather_annot_files.ipynb"
