library(magrittr)

# if (!file.exists("analysis/data/derived_data/detections.rds")){
#   source("scripts/2_preprocess_detections.R")
# } else {
#   dets <- readRDS("analysis/data/derived_data/detections.rds")
# }

# ls_out <- readr::read_csv("out_542011_output.csv", col_types = readr::cols(
#   id = readr::col_character(),
#   type = readr::col_character(),
#   origin = readr::col_character(),
#   to_name = readr::col_character(),
#   variable = readr::col_character(),
#   original_width = readr::col_double(),
#   original_height = readr::col_double(),
#   value_x = readr::col_double(),
#   value_y = readr::col_double(),
#   value_width = readr::col_double(),
#   value_height = readr::col_double(),
#   value_rectanglelabels = readr::col_character(),
#   source_file = readr::col_character(),
#   tag = readr::col_character(),
#   value_text = readr::col_character()
# ))
#
# ls_out <- ls_out %>%
#   dplyr::select(-type) |>
#   dplyr::mutate(manual = stringr::str_detect(id, "_M")) |>
#   dplyr::mutate(image_id = stringr::str_split(id, "_")) |>
#   dplyr::mutate(image_id =
#                   unlist(purrr::map(image_id,
#                                     ~paste0(.x[1:5], collapse = "_")))) |>
#   tidyr::pivot_wider(names_from = "variable", values_from = "tag") # |>
#   # dplyr::filter(is.na(value_text)) |>
#   # dplyr::mutate (species = ifelse(species == 'Other [See more species]',
#   #                                 other_species, species)) |>
#   # dplyr::select(-other_species)

# -------------------------------------------------------------------------

ls_out <- jsonlite::fromJSON("/media/vlucet/TrailCamST/P312_out_ls.json",
                             simplifyVector = T,
                             flatten = T)
coco <- jsonlite::fromJSON("/media/vlucet/TrailCamST/TrailCamStorage/P312_output_coco.json",
                           simplifyVector = T,
                           flatten = T)
# ----

norep <- jsonlite::fromJSON("/media/vlucet/TrailCamST/TrailCamStorage/P312_output_coco_norepeats.json",
                            simplifyVector = F,
                            flatten = T)
ls_in <- jsonlite::fromJSON("/media/vlucet/TrailCamST/TrailCamStorage/P312_output_ls.json",
                            simplifyVector = F,
                            flatten = T)

# ----

target <- jsonlite::fromJSON("/media/vlucet/TrailCamST/P312_test.json",
                             simplifyVector = T,
                             flatten = T)

# export <- jsonlite::fromJSON("export_P312.json", flatten = T)
# here



new_ls_in <- ls_in
new_ls_in[["annotations"]] <- new_ls_in$predictions

for (i in seq_len(nrow(new_ls_in))) {

  print(i)

  path <- new_ls_in$data.image[i]
  path_short <-
    c(stringr::str_split_fixed(str = unlist(strsplit(path, "data/local-files/?d=TrailCamStorage/",
                                                     fixed=T))[2], pattern = "/", n = 2))[2]

  print(path_short)

  if (path_short %in% norep$images$file_name) {

    new_ls_in[["annotations"]][[i]] <- new_ls_in$predictions[[i]]

    # new_ls_in[[i]]$predictions <- NA

  }

}

# -------------------------------------------------------------------------

filt_dets <- norep$annotations %>%
  dplyr::mutate(is_filtered_out = ifelse(confidence<0,TRUE,FALSE),
                from_filter = 1) %>%
  dplyr::select(-bbox, -max_confidence, -isempty) %>%
  dplyr::rename(confidence_mod=confidence,
                categ_filt = category_id) %>%
  dplyr::filter(confidence_mod > 0.1 | confidence_mod < 0)

dets_P081 <- dets %>%
  dplyr::filter(stringr::str_detect(id, "P081"))
dets_P081_joined <- dets_P081 %>%
  dplyr::left_join(filt_dets, by = dplyr::join_by(id, image_id))

# dets_P081_joined_noNA <- dets_P081_joined %>%
#   dplyr::filter(!is.na(confidence)) %>%
#   dplyr::filter(confidence > 0.1)
#
# anns_P081 <- anns_wide %>%
#   dplyr::filter(stringr::str_detect(id, "P081"))
# anns_P081_joined <- anns_P081 %>%
#   dplyr::right_join(filt_dets, by = dplyr::join_by(id, image_id))
#
# anns_P081_joined
# table(anns_P081_joined$label_rectangles, anns_P081_joined$is_filtered_out, useNA = "ifany")

# -------------------------------------------------------------------------

large_list <- c("Q647", "P352", "P323", "P216", "P132", "P128", "P121",
                "P100", "P092", "P095", "P087", "P058", "P045", "P030",
                "P328", "P293", "P080")

large_list <- c( "P224")

for (folder in large_list) {

  file_in <- paste0("/media/vlucet/TrailCamST/culling/",folder,"_out_ls.json")

  if (file.exists(file_in)){

    ls_out <- jsonlite::fromJSON(txt = file_in,
                                 simplifyVector = F,
                                 flatten = F)
    names(ls_out) <- unlist(lapply(ls_out, function(x){unlist(x$data$image)}))

    ls_norep <- jsonlite::fromJSON(txt = paste0("/media/vlucet/TrailCamST/TrailCamStorage/",folder,"_output_ls_norepeats.json"),
                                   simplifyVector = F,
                                   flatten = F)
    names(ls_norep) <- unlist(lapply(ls_norep, function(x){unlist(x$data$image)}))

    ls_norep_ann <- ls_norep
    for (image in names(ls_norep_ann)){
      ls_norep_ann[[image]][["annotations"]] <- ls_out[[image]][["annotations"]]
    }

    for (image in names(ls_out)){
      if (is.null(ls_norep_ann[[image]][["annotations"]])){
        if (!is.null(ls_out[[image]][["annotations"]])) {
          ls_norep_ann[[image]] <- ls_out[[image]]
        }
      }
    }


    jsonlite::write_json(unname(ls_norep_ann),
                         paste0("/media/vlucet/TrailCamST/culling/",folder,"_culled_for_ls_norepeats.json"),
                         auto_unbox = TRUE)
  }

}
