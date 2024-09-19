#!/bin/bash -euo pipefail
zcat \
    -f \
    FAZ50517_pass_barcode01_506ab4d4_460c1d0d_0.fastq.gz | \
chopper \
    --threads 2 \
    -q 10 | \
gzip \
    -9 > FAZ50517_pass_barcode01_506ab4d4_460c1d0d_0.trimmed.fastq.gz

cat <<-END_VERSIONS > versions.yml
"AMRNANOPRO:CHOPPER":
    chopper: $(chopper --version 2>&1 | cut -d ' ' -f 2)
END_VERSIONS
