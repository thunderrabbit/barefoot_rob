git fast-export --import-marks=../journal.git.marks  --export-marks=../journal.git.marks  \
        --all | fossil import --git --incremental --import-marks        \
		       ../journal.fossil.marks --export-marks ../journal.fossil.marks journal.fossil

fossil sync
