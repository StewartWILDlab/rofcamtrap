## Utilities for cropping files from annotations

#' @export
make_crop_name_label <- function(the_row,
                                 dest_folder ) {
  img_name <-
    paste0(out_folder,
           stringr::str_replace_all(stringr::str_replace_all(
             the_row$species, pattern = c(" "), replacement = "_"),
             pattern = stringr::fixed("."), replacement = ""), "_", the_row$id)
  return(img_name)
}

#' @export
crop_from_annotations <- function(annotations,
                                  dest_folder = "/media/vlucet/TrailCamST/Cropped/all/") {



}
