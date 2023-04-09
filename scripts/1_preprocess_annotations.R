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
    value_rectanglelabels = readr::col_character(),
    source_file = readr::col_character(),
    tag = readr::col_character(),
    value_text = readr::col_character()
  ))

  annotations <- dplyr::bind_rows(annotations, outls)

}

annotations <- annotations %>%
  dplyr::mutate(value_rectanglelabels =
                  stringr::str_remove(value_rectanglelabels,
                                      stringr::fixed("['"))) %>%
  dplyr::mutate(value_rectanglelabels =
                  stringr::str_remove(value_rectanglelabels,
                                      stringr::fixed("']")))

saveRDS(annotations, "analysis/data/derived_data/annotations.rds")

# Wide format -------------------------------------------------------------

annotations_wide <- annotations |>
  dplyr::select(-type) |>
  dplyr::mutate(manual = stringr::str_detect(id, "_M")) |>
  dplyr::mutate(image_id = stringr::str_split(id, "_")) |>
  dplyr::mutate(image_id =
                  unlist(purrr::map(image_id,
                                    ~paste0(.x[1:5], collapse = "_")))) |>
  tidyr::pivot_wider(names_from = "variable", values_from = "tag") |>
  dplyr::filter(is.na(value_text)) |>
  dplyr::mutate (species = ifelse(species == 'Other [See more species]',
                                  other_species, species)) |>
  dplyr::select(-other_species)

saveRDS(annotations_wide, "analysis/data/derived_data/annotations_wide.rds")
