# Note: This runs on the csvs created from the label studio json outputs by
# the post process function in the python utility mdtools

# for FILE in *
#   mdtools postprocess --write-csv $FILE
# end

library(magrittr)

# Folder with label studio annotation outputs
label_studio_folder <- "analysis/data/raw_data/label_studio_outputs/"

# Annotations -------------------------------------------------------------

read_ls_file <- function(the_file){
  readr::read_csv(the_file, col_types = readr::cols(
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
}

widen <- function(df) {
  df %>%
    dplyr::select(-type) |>
    dplyr::mutate(manual = stringr::str_detect(id, "_M")) |>
    dplyr::mutate(image_id = stringr::str_split(id, "_")) |>
    dplyr::mutate(image_id =
                    unlist(purrr::map(image_id,
                                      ~paste0(.x[1:5], collapse = "_")))) |>
    tidyr::pivot_wider(names_from = "variable", values_from = "tag") |>
    dplyr::filter(is.na(value_text)) |>
    dplyr::mutate (species = ifelse(species == 'Other [See more species]',
                                    other_species, species)) # |>
    # dplyr::select(-other_species)
}

# List all the files with the proper file name format
file_list <- list.files(label_studio_folder, recursive = F,
                        full.names = T, pattern = "output.csv")

# Create an empty dataframe to be grown
annotations_no_dup <- data.frame()
annotations_dup <- data.frame()

# separate into dups and not dups. process not dups normally and
# process dups specifically
projects <- unlist(lapply(stringr::str_split(basename(file_list), "_"), function(x)x[1]))
names(file_list) <- projects
dups_names <- names(which(table(projects)>1))
non_dups_names <- names(which(!(table(projects)>1)))

file_list_no_dups <- file_list[names(file_list) %in% non_dups_names]
file_list_dups <- file_list[names(file_list) %in% dups_names]

# -------------------------------------------------------------------------

for (file in file_list_no_dups){

  # print(file)

  outls <- read_ls_file(file)

  annotations_no_dup <- dplyr::bind_rows(annotations_no_dup, outls)

}

annotations_no_dup <- annotations_no_dup %>%
  dplyr::mutate(value_rectanglelabels =
                  stringr::str_remove(value_rectanglelabels,
                                      stringr::fixed("['"))) %>%
  dplyr::mutate(value_rectanglelabels =
                  stringr::str_remove(value_rectanglelabels,
                                      stringr::fixed("']")))

# saveRDS(annotations, "analysis/data/derived_data/annotations.rds")

# ------------------------------------------------------------------------

library(magrittr)

is_numerical_id <- function(x){
  !(stringr::str_detect(x, "P") | stringr::str_detect(x, "Q"))
}

all_anns <- data.frame()
for (dup in dups_names){

  print(dup)

  dup_files <- file_list_dups[names(file_list_dups) %in% dup]

  assertthat::assert_that(length(dup_files)==2)

  outls_1 <- read_ls_file(dup_files[1]) %>% dplyr::mutate(orig=1)
  outls_2 <- read_ls_file(dup_files[2]) %>% dplyr::mutate(orig=2)

  annotations_dup <- dplyr::bind_rows(outls_1, outls_2)

  annotations_dup_wide <- widen(annotations_dup) %>%
    dplyr::group_by(source_file) %>% tidyr::nest() %>%
    dplyr::mutate(nr = unlist(purrr::map(data, ~nrow(.x)))) %>%
    dplyr::arrange(dplyr::desc(nr))

  anns <- data.frame()

  for (r in 1:nrow(annotations_dup_wide)){

    row <- annotations_dup_wide[r,]
    row_nr <- row$nr
    row_df <- tidyr::unnest(row, cols = c(data)) %>%
      tidyr::replace_na(list(species = "None"))

    id_test <- sapply(row_df$id, is_numerical_id)

    row_df_1 <- row_df %>% dplyr::filter(orig == 1) %>%
      dplyr::select(-orig)
    row_df_2 <- row_df %>% dplyr::filter(orig == 2) %>%
      dplyr::select(-orig)

    if (nrow(row_df_1) == nrow(row_df_2)){
      if (all(row_df_1$species == row_df_2$species)){
        if (all(row_df_1$id == row_df_2$id)){
          # exact same information
          # print ("same id and species")
          # keep older origin
          anns <- dplyr::bind_rows(anns, row_df_1)
        } else {
          # print ("same species, different id")
          # 2 rows, both NAs, numerical IDs
          if (all(c(row_df_1$species, row_df_2$species) == "None")){
            if (all(c(nrow(row_df_1) == 1, nrow(row_df_2) == 1))){
              if(all(id_test)){
                # take smaller id
                to_keep <- row_df[which.min(as.numeric(row_df$id)),]
                anns <- dplyr::bind_rows(anns, to_keep)
              } else if (sum(id_test) == 1) {
                # take the one that is not numerical, use id_test for indexing
                to_keep <- row_df[!id_test,]
                anns <- dplyr::bind_rows(anns, to_keep)
              } else  {
                print(row_df)
                stop("Unexpected format 1")
              }
            } else {
              print(row_df)
              stop("Unexpected format 2")
            }
          } else {
            print(row_df)
            stop("Unexpected format 3")
          }
        }
      } else {
        # this would mean an update, not all repos will have it
        # print ("species different")
        print(row_df)
        stop("Here")
      }
    } else {

      # print ("different nb of rows")

      if (nrow(row_df_1) == 0 | nrow(row_df_2) == 0) {
        if (nrow(row_df_2) == 0) {
          # just keep all the ones from orig 1
          anns <- dplyr::bind_rows(anns, row_df_1)
        } else if (nrow(row_df_1) == 0) {
          # just keep all the ones from orig 2
          anns <- dplyr::bind_rows(anns, row_df_2)
        } else {
          print(row_df)
          stop("Unexpected format 4")
        }
      } else if ((sum(id_test) == 1) & all(row_df$species == "None")){
        # Keep the not NA rows
        to_keep <- row_df[!id_test,]
        anns <- dplyr::bind_rows(anns, to_keep)
      } else {
        print(row_df)
        stop("Unexpected format 5")
      }

    }

  }

  all_anns <- dplyr::bind_rows(all_anns, anns) # %>%
    # dplyr::select(-orig)

}

# for(y in 1:500){x$data[[y]] %>% dplyr::relocate(species, .after = id)%>% View();readline()}

# Wide format -------------------------------------------------------------

annotations_wide <- widen(annotations_no_dup) %>%
  dplyr::bind_rows(all_anns) %>%
  dplyr::mutate(species = ifelse(species == "None", NA, species))

saveRDS(annotations_wide, "analysis/data/derived_data/annotations_wide_treated.rds")
