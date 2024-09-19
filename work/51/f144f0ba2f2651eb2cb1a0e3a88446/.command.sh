#!/bin/bash -euo pipefail
NanoPlot \
    -p _before_chopper \
    -t 2 \
    --fastq FAZ50517_pass_barcode01_506ab4d4_460c1d0d_0.fastq.gz

cat <<-END_VERSIONS > versions.yml
"AMRNANOPRO:NANOPLOT_BEFORE_CHOPPER":
    nanoplot: $(echo $(NanoPlot --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*$//')
END_VERSIONS
