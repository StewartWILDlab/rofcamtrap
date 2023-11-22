## code to prepare `rof_survey` dataset

# Load packages
library(readxl)
library(janitor)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)

# Load both sheets
rof_survey_summary_raw <-
  readxl::read_xlsx("data-raw/RoF_CameraDeploymentLog_WLU.xlsx",
                    sheet = "Summary", col_names = FALSE)
rof_survey_raw <-
  readxl::read_xlsx("data-raw/RoF_CameraDeploymentLog_WLU.xlsx",
                    sheet = "Sheet1")

# Clean up summary
names(rof_survey_summary_raw) <- c("key", "value")
rof_survey_summary_clean <- rof_survey_summary_raw %>%
  dplyr::slice(-3)


# Clean up survey

# Needed function
split_fun <- function(x, i) {
  if (length(x) <= 1){
    return(NA)
  } else {
    return(x[i])
  }
}

assembly_fun <- function(x) {
  if (length(x) <= 1){
    return(NA)
  } else {
    return(file.path(x[3], x[4], x[5]))
  }
}

rof_survey_clean <-
  rof_survey_raw %>%
  # Clean the column names
  janitor::clean_names() %>%
  # Deal with time columns
  dplyr::rename(date_deployed_full = date_deployed,
                date_retrieved_full = date_retrieved) %>%
  dplyr::mutate(date_deployed_full = lubridate::ymd_hms(date_deployed_full),
                date_deployed = lubridate::date(date_deployed_full),
                date_retrieved_full = lubridate::ymd(date_retrieved_full),
                date_retrieved = lubridate::date(date_retrieved_full),
                deploy_interval = date_retrieved - date_deployed) %>%
  # Deal with paths
  dplyr::rename(photo_storage_network_location_SF =
                  photo_storage_network_location) %>%
  dplyr::mutate(photo_storage_network_location_split =
                  stringr::str_split(photo_storage_network_location_SF,
                                     pattern = "\\\\"),
                photo_storage_network_location_root = sapply(photo_storage_network_location_split,
                                                             FUN = split_fun, 2),
                photo_storage_network_location_path = sapply(photo_storage_network_location_split,
                                                             FUN = assembly_fun))

# Use datasets in package
usethis::use_data(rof_survey_summary_clean, overwrite = TRUE)
usethis::use_data(rof_survey_clean, overwrite = TRUE)
