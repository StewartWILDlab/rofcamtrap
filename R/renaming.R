
rename_images <- function(images_from,
                          images_to,
                          deployment_code,
                          locations_subset = c(),
                          file_ext = "\\.(jpg|jpeg|JPG|JPEG)$") {

  # Get all location folders in this deployment, some will have _repeat or _crop
  # in them, due to the way things were done before
  locations_all <- list.dirs(images_from, recursive = FALSE, full.names = FALSE)
  # Remove those repeat folders from the list
  locations <- locations_all[!(grepl("repeat", locations_all) |
                                 grepl("crop", locations_all))]

  # Subset if necessary
  if (length(locations_subset) > 0) {
    locations <- locations[locations %in% locations_subset]
  }
  print(locations)

  # For all locations, proceed to the copy and renaming
  # TODO improve performance
  for (loc in locations) {

    message(paste("Proccessing folder", loc))

    # Path to location dir
    root_path <- file.path(images_from, loc)
    # List all images
    all_images <- list.files(root_path, recursive = TRUE, pattern = file_ext)

    print(all_images)
    stop()

    # For all images, make the appropriate file name
    pb <- progress::progress_bar$new(total = length(all_images))
    for (image in all_images) {

      # Reconstruct image path
      old_path <- file.path(root_path, image)

      # Split at appropriate file separator
      image_split <- strsplit(image, .Platform$file.sep) |>
        unlist()

      # Filter the path for useless sections, removing DCIM first
      image_split_filtered <-  image_split[!(image_split %in% c("DCIM"))] |>
          # Remove useless suffix for overflow folder and file name
          gsub(pattern = "RECNX", replacement = "") |>
          gsub(pattern = "RCNX", replacement = "") |>
          gsub(pattern = file_ext, replacement = "")

      # Get datetime from exif data
      exif <- exifr::read_exif(old_path)
      datetime <- exif$DateTimeOriginal |>
        gsub(pattern = ":", replacement = "_") |>
        gsub(pattern = " ", replacement = "_") |>
        gsub(pattern = "Wildlife", replacement = "W") |>
        gsub(pattern = "NonWildlife", replacement = "W")

      # Construct the new file name...
      new_name <- paste0(
        paste0(c(deployment_code, loc,
                 paste0(image_split_filtered, collapse = "_"), datetime),
               collapse = "_"),
        ".JPG")

      # ...and new file path
      new_path <- file.path(images_to, deployment_code,
                            paste0(c(deployment_code, loc,image_split_filtered[1:2]), collapse = "_"),
                            new_name)

      if (!file.exists(dirname(new_path))) {
        dir.create(dirname(new_path), recursive = TRUE)
        message(paste("Created path", dirname(new_path)))
      }

      if (!file.exists(new_path)) {
        # message(paste(
        #   "Coppying", old_path, "to", new_path
        # ))
        file.copy(old_path, new_path)
      }

      pb$tick()
    }

  }

}
