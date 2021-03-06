# List model names and file directories for access through the updating pipeline
#   i.e. update > ensemble > plot > score

model_list <- list(
  # Models
  "single_models" = list(
    # --------------
    # Add a new model (single or ensemble) to be fed through the pipeline using the following format:
    # model_name = 
    # list("name" = "model_name",                                       # Unique model name e.g. used in plotting
    #      "root" = here::here(model_folder),                           # Root model folder - may be shared with other models
    #      "update" = "/update.R",                                      # Update script accessed from root  - may be shared
    #      "submission_file" = "/output/model_name/submission-files",   # Model specific output files
    #      "colour" = "colour_name")                                    # Plotting colour: try https://htmlcolorcodes.com/color-chart/
    # --------------
    # 
    # Rt Epinow2 - original
    "rt2_original" = 
      list("name" = "Rt2 original",
           "root" = "rt-forecast-2",
           "update" = "update.R",
           "submission_files" = "output/original/submission-files",
           "colour" = "#800000"),
    # Rt Epinow2 - fixed future Rt
    "rt2_fixed_future_rt" =
      list("name" = "Rt2 fixed future rt",
           "root" = "rt-forecast-2",
           "update" = "update.R",
           "submission_files" = "output/fixed_future_rt/submission-files",
           "colour" = "#DB7093"),
    # Rt Epinow2 - fixed Rt
    "rt2_fixed_rt" =
      list("name" = "Rt2 fixed rt",
           "root" = "rt-forecast-2",
           "update" = "update.R",
           "submission_files" = "output/fixed_rt/submission-files",
           "colour" = "#E9967A"),
    # Rt Epinow2 - no modelling of delays
    "rt2_no_delay" =
      list("name" = "Rt2 (no delays)",
           "root" = "rt-forecast-2",
           "update" = "update.R",
           "submission_files" = "output/no_delay/submission-files",
           "colour" = "#FF4500"),
     # Rt Epinow2 - using backcalculation
    "rt2_backcalc" =
      list("name" = "Rt2 backcaculation",
           "root" = "rt-forecast-2",
           "update" = "update.R",
           "submission_files" = "output/backcalc/submission-files",
           "colour" = "#ffc500"),
    "secondary" =
      list("name" = "secondary",
           "root" = "deaths-conv-cases",
           "update" = "update.R",
           "submission_files" = "deaths-conv-cases/data/submission",
           "colour" = "#326194"),
    # Timeseries - weekly
    "ts_weekly_deaths_only" = 
      list("name" = "TS weekly deaths",
           "root" ="timeseries-forecast",
           "update" =  "update.R",
           "submission_files" = "deaths-only/submission-files",
           "colour" = "#336600"),
    "ts_weekly_deaths_on_cases" = 
      list("name" = "TS weekly deaths-cases",
           "root" = "timeseries-forecast",
           "update" = "update.R",
           "submission_files" = "deaths-on-cases/submission-files",
           "colour" = "#33CC00")
    # ,
    # # Expert elicitation
    # "expert" = 
    #   list("name" = "Expert",
    #        "root" = here::here("expert-forecast"),
    #        "update" = "/update-expert.R",
    #        "submission_files" = "/submission-files",
    #        "colour" = "#00FFFF")
    # Add new single models here
    ),
  # Ensembles
  "ensemble_models" = list( 
    "mean_ensemble" = 
      list("name" = "Mean ensemble",
           "root" = "ensembling/quantile-average",
           "update" = "update-equal-quantile-average.R",
           "submission_files" = "submission-files",
           "colour" = "#66FFFF"),
    "qra_ensemble" = 
      list("name" = "QRA all",
           "root" = "ensembling/qra-ensemble",
           "update" = "update-qra-ensemble.R",
           "submission_files" = "submission-files",
           "colour" = "#6666CC"),
    "qra_state" = 
      list("name" = "QRA by state",
           "root" = "ensembling/qra-state-ensemble",
           "update" = "update-state-qra-ensemble.R",
           "submission_files" = "submission-files",
           "colour" = "#6600CC"),
    "qra_sum_states" = 
      list("name" = "QRA sum of states",
           "root" = "ensembling/qra-ensemble-sum-of-states",
           "update" = "update-sum-of-states-qra-ensemble.R",
           "submission_files" = "submission-files",
           "colour" = "#6699FF")
    # Add new ensemble models here
  )
)

saveRDS(model_list, here::here("utils", "model_list.rds"))
