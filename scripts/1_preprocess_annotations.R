# Note: This runs on the csvs created from the label studio json outputs by
# the post process function in the python utility mdtools

# Folder with label studio annotation outputs
label_studio_folder <- "analysis/data/raw_data/label_studio_outputs/"

# Annotations -------------------------------------------------------------

# List all the files with the proper file name format
file_list <- list.files(label_studio_folder, recursive = F,
                        full.names = T, pattern = "output.csv")

# Create an empty dataframe to be grown
annotations <- data.frame()

for (file in file_list){

  # print(file)

  outls <- readr::read_csv(file, col_types = readr::cols(
    id = readr::col_character(),
    type = readr::col_character(),
    origin = readr::col_character(),
    to_name = readr::col_character(),
    variable = readr::col_character(),
    original_width = readr::col_double(),
    original_height = readr::col_double(),
    value_x = readr::col_double(),
    value_y = readr::col_double(),
    value_width = readr::col_double(),
    value_height = readr::col_double(),
    source_file = readr::col_character(),
    tag = readr::col_character(),
    value_text = readr::col_character()
  ))

  annotations <- dplyr::bind_rows(annotations, outls)

}

saveRDS(annotations, "analysis/data/derived_data/annotations.rds")

# -------------------------------------------------------------------------

# TODO dead code

# anns <- readRDS("data/anns.rds")
# Check for duplicates (should have been caught by python code)
# test <- anns %>% dplyr::filter(variable == "species" |
#                                  variable == "other_species",
#                                tag != "Human",
#                                tag != "Vehicle")  %>%
#   dplyr::group_by(id, type, origin, to_name, original_width, original_height,
#                   value_x, value_y, value_width, value_height, source_file,
#                   value_text, variable) %>%
#   dplyr::summarise(n = dplyr::n(), .groups = "drop") %>%
#   dplyr::filter(n > 1L)
