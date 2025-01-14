# load packages
library(ggplot2)
library(scales)
library(dplyr)
library(here)
library(readr)

# takes a dataframe voc_frac : date, region, median, q5, q95 estimates

# Earliest date at 95% Omicron ---------------------------------------
plot_omicron_95 <- function(voc_frac, forecast_start, forecast_end) {

  omicron_95 <- voc_frac %>%
    as_tibble() %>%
    select(date, region, q_median = median, q5, q95, q20, q80) %>%
    pivot_longer(cols = starts_with("q"),
                 names_to = "quantile", values_to = "omicron_prop") %>%
    mutate(quantile = factor(quantile)) %>%
    group_by(region, quantile) %>%
    filter(omicron_prop >= 0.95) %>%
    slice_min(date) %>%
    ungroup() %>%
    complete(quantile) %>%
    select(region, quantile, date) %>%
    pivot_wider(id_cols = region, names_from = quantile, values_from = date) %>%
    mutate(
      across(starts_with("q"),
             ~ as.Date(ifelse(is.na(.x), forecast_end, .x),
                       origin = lubridate::origin))
    ) %>%
    arrange(q_median) %>%
    mutate(region = factor(region, ordered = TRUE)) %>%
    filter(!is.na(region))

  plot_95_percent <- omicron_95 %>%
    mutate(region = forcats::fct_rev(region)) %>%
    ggplot(aes(y = region)) +
    geom_point(aes(x = q_median)) +
    geom_linerange(aes(xmin = q5, xmax = q95), alpha = 0.3, size = 3) +
    geom_linerange(aes(xmin = q20, xmax = q80), alpha = 0.3, size = 3) +
    geom_vline(xintercept = forecast_start, lty = 5, lwd = 1, col = "black") +
    labs(y = NULL, x = "Date when 95% of reported cases are Omicron")

  # copy code from forecast.vocs::plot_theme() to avoid overwriting x limits
  plot_95_percent <- plot_95_percent +
    theme_bw() +
    theme(legend.position = "bottom", legend.box = "vertical") +
    scale_x_date(date_breaks = "1 day", date_labels = "%b %d") +
    theme(axis.text.x = element_text(angle = 90))

  return(plot_95_percent)
}
