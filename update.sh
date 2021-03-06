#!bin/bash

# Source this script to run a complete submission update end-to-end

# Update packages
Rscript utils/package-check.R

# Update the data
Rscript utils/get-us-data.R

# Update forecast and submission dates
Rscript utils/current-forecast-submission-date.R

# update visualisation of the data without forecasts
Rscript evaluation/utils/update-visualise-raw-data.R

# Update single models
Rscript utils/update-single-models.R

# # Update intermediate models (expert etc.)
# Rscript utils/update-intermediate-models.R

# Update ensembles models
Rscript utils/update-ensemble-models.R

# Update evaluation
Rscript evaluation/update.R

# Update submission
Rscript final-submissions/update-final-submission.R

# Submit
# See: https://github.com/reichlab/covid19-forecast-hub/blob/master/data-processed/README.md
