
library(magrittr)
source(here::here("utils", "load-submissions-function.R"))
source(here::here("utils", "current-forecast-submission-date.R"))


# get weights ------------------------------------------------------------------

# load past forecasts
past_forecasts <- load_submission_files(dates = "all",
                                        num_last = 5, #
                                        models = "single") 

# Remove latest week
past_forecasts <- past_forecasts[past_forecasts$forecast_date < forecast_date , ]

## Note: code to remove duplicates has been commented out. 
full_set <- past_forecasts %>%
  dplyr::select(-forecast_date) %>%
  # remove complete duplicates
  # dplyr::distinct() %>%
  # remove point forecasts and cumulative forecasts
  dplyr::filter(type == "quantile", 
                grepl("inc", target)) %>%
  dplyr::select(-type) %>%
  # # filter out duplicate predictions for the exact same target quantile
  # dplyr::group_by(submission_date, target, target_end_date, location, quantile, model) %>%
  # dplyr::slice(1) %>%
  # dplyr::ungroup() %>%
#  remove targets for which not all models have a forecast
  dplyr::group_by(submission_date, target, target_end_date, location, quantile) %>%
  dplyr::add_count() %>%
  dplyr::ungroup() %>%
  dplyr::filter(n == max(n)) %>%
  dplyr::select(-n) 

# store quantiles available
tau <- full_set$quantile %>%
  round(digits = 3) %>%
  unique()

# load deaths
source(here::here("utils", "get-us-data.R"))
deaths_data <- get_us_deaths(data = "daily") %>%
  dplyr::group_by(epiweek, state) %>%
  dplyr::summarise(deaths = sum(deaths), .groups = "drop_last")

# Remove recent data
deaths_data <- deaths_data[deaths_data$epiweek < lubridate::epiweek(forecast_date) , ]


# join deaths with past forecasts and reformat
combined <- full_set %>%
  dplyr::mutate(epiweek = lubridate::epiweek(target_end_date)) %>%
  dplyr::inner_join(deaths_data, by = c("state", "epiweek")) %>%
  tidyr::pivot_wider(values_from = value, names_from = quantile, 
                     names_prefix="quantile_") %>%
  dplyr::arrange(submission_date, target, target_end_date, location, model, epiweek) %>%
  dplyr::select(-c(submission_date, target, target_end_date, location, epiweek, state)) 

# extract true values and check if they have the correct length
models <- unique(combined$model)

true_values <- combined %>%
  dplyr::group_by(model) %>%
  dplyr::mutate(n = 1:dplyr::n()) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(n) %>%
  dplyr::summarise(deaths = unique(deaths), .groups = "drop_last") %>%
  .$deaths

# this should be TRUE
if(!(length(true_values) == (nrow(combined))  / length(models))){
  warning("QRA: check that true values and models align")
}

# extract forecasts as matrices and store as quantgen array
qarr <- combined %>%
  dplyr::select(-deaths) %>%
  dplyr::group_split(model, .keep = FALSE) %>%
  setNames(models) %>%
  purrr::map(.f = as.matrix) %>%
  quantgen::combine_into_array()

model_weights <- quantgen::quantile_ensemble(qarr = qarr, 
                                             y = true_values, 
                                             tau = tau)$alpha

message("QRA weights:")
message(paste0("\n", models, "\n", model_weights, "\n"))

# ensembling -------------------------------------------------------------------
forecasts <- load_submission_files(dates = "all",
                                   num_last = 1,
                                   models = "single")

# pivot_wider
forecasts_wide <- forecasts %>%
  dplyr::select(-forecast_date) %>%
  dplyr::mutate(quantile = round(quantile, digits = 3)) %>%
  tidyr::pivot_wider(names_from = model,
                     values_from = value)

# Set negative to 0; select weights for forecasting models
model_weights <- ifelse(model_weights < 0, 0, model_weights)
forecast_models <- colnames(dplyr::select(forecasts_wide, 
                                 dplyr::starts_with("rt") | 
                                   dplyr::starts_with("ts")))
names(model_weights) <- models
forecast_model_weights <- model_weights[names(model_weights) %in% forecast_models]


qra_ensemble <- forecasts_wide %>%
  dplyr::mutate(ensemble = forecasts_wide %>% 
                  dplyr::select(all_of(forecast_models)) %>%
                  as.matrix() %>%
                  matrixStats::rowWeightedMeans(w = forecast_model_weights, 
                                                na.rm = TRUE)) %>%
  dplyr::rename(value = ensemble) %>%
  dplyr::select(-dplyr::all_of(forecast_models)) %>%
  dplyr::mutate(forecast_date = max(unique(past_forecasts$submission_date))) %>%
  dplyr::select(forecast_date, submission_date, target, target_end_date, location, type, quantile, value) %>%
  # round values after ensembling
  dplyr::mutate(value = round(value)) 



# write dated file
data.table::fwrite(qra_ensemble, here::here("ensembling", "qra-ensemble", 
                                            "submission-files","dated",
                                            paste0(forecast_date, "-epiforecasts-ensemble1-qra.csv")))
# write Latest files
data.table::fwrite(qra_ensemble, here::here("ensembling", "qra-ensemble", "submission-files",
                                            paste0("latest.csv")))

