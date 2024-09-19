#!/bin/bash -euo pipefail
multiqc \
    --force \
     \
    .

cat <<-END_VERSIONS > versions.yml
"AMRNANOPRO:MULTIQC":
    multiqc: $( multiqc --version | sed -e "s/multiqc, version //g" )
END_VERSIONS
