# Plot timeseries forecasts
# Arguments:
# model_type <- "deaths-only"
# date <- "2020-07-06"
# right_truncate_weeks = 1
# xlim_min = max(fc_state$epiweek_target)-12
# id = NULL

library(ggplot2); library(dplyr); library(tidyr); library(stringr)

plot_timeseries <- function(model_type, date = "latest", right_truncate_weeks = 1, 
                            xlim_min = 10, id = NULL){

  # Read in forecast
  weekly_forecast <- readRDS(here::here("timeseries-forecast", model_type, "raw-rds",
                                        paste0(date, "-weekly-", model_type, ".rds")))
  
  # Get data
  source(here::here("utils", "get-us-data.R"))
  daily_deaths_state <- get_us_deaths(data = "daily") %>%
    mutate(epiweek = lubridate::epiweek(date),
           day = ordered(weekdays(as.Date(date)), 
                         levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")),
           epiweek = as.numeric(paste0(epiweek, ".", as.numeric(day))))
  
  daily_cases_state <- get_us_cases(data = "daily") %>%
    mutate(epiweek = lubridate::epiweek(date),
           day = ordered(weekdays(as.Date(date)), 
                         levels=c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")),
           epiweek = as.numeric(paste0(epiweek, ".", as.numeric(day))))
  
  
  # States ------------------------------------------------------------------
  
  weekly_deaths_state <- daily_deaths_state %>%
    mutate(epiweek = lubridate::epiweek(date),
           date = NULL) %>%
    group_by(state, epiweek) %>%
    summarise(deaths = sum(deaths))
  
  weekly_cases_state <- daily_cases_state %>%
    mutate(epiweek = lubridate::epiweek(date),
           date = NULL) %>%
    group_by(state, epiweek) %>%
    summarise(cases = sum(cases))
  
  keep_states <- filter(weekly_deaths_state, epiweek == max(epiweek)-1 & deaths > 50) %>%
    pull(state)
  
  weekly_deaths_state <- filter(weekly_deaths_state, state %in% keep_states)
  daily_deaths_state <- filter(daily_deaths_state, state %in% keep_states)
  
  weekly_cases_state <- filter(weekly_cases_state, state %in% keep_states)
  daily_cases_state <- filter(daily_cases_state, state %in% keep_states)
  
  # Reshape forecast for plotting
  fc_state <- weekly_forecast %>%
    filter(state %in% keep_states) %>%
    group_by(state, epiweek_target) %>%
    mutate(quantile = stringr::str_c("c", quantile)) %>%
    filter(quantile %in% c("c0.05", "c0.25", "c0.5", "c0.75", "c0.95")) %>%
    tidyr::pivot_wider(id_cols = c(state, epiweek_target), names_from = quantile, values_from = deaths) %>%
    ungroup()
  
  
  # Plot
  plot_state <- fc_state %>%
    ggplot2::ggplot(ggplot2::aes(x = epiweek_target)) +
    ggplot2::geom_line(ggplot2::aes(y = c0.5)) +
    ggplot2::geom_line(data = weekly_deaths_state, ggplot2::aes(x = epiweek, y = deaths), col = "blue") +
    ggplot2::geom_line(data = daily_deaths_state, ggplot2::aes(x = epiweek, y = deaths), col = "light blue") +
    ggplot2::geom_line(data = weekly_cases_state, ggplot2::aes(x = epiweek, y = cases/100), col = "grey") +
    ggplot2::geom_ribbon(alpha = 0.2, ggplot2::aes(ymin = c0.05, ymax = c0.95)) +
    ggplot2::geom_ribbon(alpha = 0.2, ggplot2::aes(ymin = c0.25, ymax = c0.75)) +
    ggplot2::facet_wrap("state", scales = "free_y") +
    ggplot2::xlim(xlim_min, max(fc_state$epiweek_target)) +
    cowplot::theme_cowplot() +
    ggplot2::ylab("Incident deaths") +
    ggplot2::xlab("Epiweek") +
    ggplot2::geom_vline(xintercept = max(weekly_deaths_state$epiweek, na.rm=T) - right_truncate_weeks, lty = 2) +
    ggplot2::labs(caption = "--- is date of data truncation
                  Cases are divided by 100 for scale",
                  title = paste0("Incident deaths in US states, from ", model_type, " model"))
  
  
  ggplot2::ggsave(filename = paste0(id, date, "-state-", model_type, ".png"), plot = plot_state, 
                  path = here::here("timeseries-forecast", "figures"),
                  width = 12, height = 6, dpi = 300)
  
  # National ----------------------------------------------------------------
  
  daily_deaths_national <- daily_deaths_state %>%
    mutate(state = "US") %>%
    group_by(epiweek) %>%
    summarise(deaths = sum(deaths))
  
  weekly_deaths_national <- daily_deaths_state %>%
    mutate(state = "US",
           epiweek = lubridate::epiweek(date)) %>%
    group_by(epiweek) %>%
    summarise(deaths = sum(deaths))
  
  daily_cases_national <- daily_cases_state %>%
    mutate(state = "US") %>%
    group_by(epiweek) %>%
    summarise(cases = sum(cases))
  
  weekly_cases_national <- daily_cases_state %>%
    mutate(state = "US",
           epiweek = lubridate::epiweek(date)) %>%
    group_by(epiweek) %>%
    summarise(cases = sum(cases))
  
  
  # Reshape forecast for plotting
  fc_national <- weekly_forecast %>%
    filter(state == "US") %>%
    mutate(quantile = stringr::str_c("c", quantile)) %>%
    filter(quantile %in% c("c0.05", "c0.25", "c0.5", "c0.75", "c0.95")) %>%
    tidyr::pivot_wider(id_cols = c(state, epiweek_target), names_from = quantile, values_from = deaths) %>%
    ungroup()
  
  
  # Plot
  plot_national <- fc_national %>%
    ggplot2::ggplot(ggplot2::aes(x = epiweek_target)) +
    ggplot2::geom_line(ggplot2::aes(y = c0.5)) +
    ggplot2::geom_line(data = weekly_deaths_national, ggplot2::aes(x = epiweek, y = deaths), col = "blue") +
    ggplot2::geom_line(data = daily_deaths_national, ggplot2::aes(x = epiweek, y = deaths), col = "light blue") +
    ggplot2::geom_line(data = weekly_cases_national, ggplot2::aes(x = epiweek, y = cases/100), col = "grey") +
    ggplot2::geom_ribbon(alpha = 0.2, ggplot2::aes(ymin = c0.05, ymax = c0.95)) +
    ggplot2::geom_ribbon(alpha = 0.2, ggplot2::aes(ymin = c0.25, ymax = c0.75)) +
    ggplot2::facet_wrap("state", scales = "free_y") +
    ggplot2::xlim(xlim_min, max(fc_national$epiweek_target)) +
    cowplot::theme_cowplot() +
    ggplot2::ylab("Incident deaths") +
    ggplot2::xlab("Epiweek") +
    ggplot2::geom_vline(xintercept = max(weekly_deaths_national$epiweek) - right_truncate_weeks, lty = 2) +
    ggplot2::labs(caption = "--- is date of data truncation
                  Cases are divided by 100 for scale",
                  title = paste0("Incident deaths in US states, from ", model_type, " model"))
  
  ggplot2::ggsave(filename = paste0(id, date, "-national-", model_type, ".png"), plot = plot_national, 
                  path = here::here("timeseries-forecast", "figures"))
  
}


