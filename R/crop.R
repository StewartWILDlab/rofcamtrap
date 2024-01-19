## Utilities for cropping files from annotations

#' @export
make_crop_name_label <- function(the_row,
                                 dest_folder) {
  img_name <-
    paste0(out_folder,
           stringr::str_replace_all(stringr::str_replace_all(
             the_row$species, pattern = c(" "), replacement = "_"),
             pattern = stringr::fixed("."), replacement = ""), "_", the_row$id)
  return(img_name)
}

#' @export
crop_from_annotations <- function(annotations,
                                  dest_folder,
                                  overwrite = FALSE,
                                  save_anns = TRUE,
                                  save_labels = TRUE) {
  annotations <- annotations |>
    dplyr::mutate(crop_name = NA)

  for (row_id in seq_len(nrow(annotations))) {

    the_row <- annotations[row,]

    if (is.na(the_row$species) ||
        (the_row$species %in% c("Human", "Vehicle"))) {
      next
    } else {

      img_name <- make_crop_name_label(the_row, dest_folder)
      annotations[row_id,"crop_name"] <- img_name

      if (!overwrite && file.exists(img_name)) {

        next

      } else {

        # print(r$id)

        img <- magick::image_read(paste0(base_folder, the_row$source_file))
        img_cropped <- magick::image_crop(img, magick::geometry_area(
          width  = (the_row$value_width/100) * the_row$original_width,
          height = (the_row$value_height/100) * the_row$original_height,
          x_off  = (the_row$value_x/100) * the_row$original_width,
          y_off  = (the_row$value_y/100) * the_row$original_height))

        magick::image_write(img_cropped, img_name)
        magick::image_destroy(img)
        magick::image_destroy(img_cropped)
        gc()

      }

    }

  }

  # if (save_anns) {
  #   saveRDS(annotations,
  #           "analysis/data/derived_data/annotations_wide_noempty_with_crop.rds")
  #
  # }
  #
  # if (save_labels) {
  #
  # }

  return(annotations)
}
