# Note: This takes the COCO formatted detections derived from the python tool
# mdtools, and outputs a table

library("purrr")

# Folder with Megadetector detections in coco format
detections_folders <- c("2_LabelStudio/0_inputs/TrailCamStorage",
                        "2_LabelStudio/0_inputs/TrailCamStorage_2")

# List all the files with the proper file name format
file_list <- map(detections_folders, list.files, recursive = F,
                 full.names = T, pattern = "output_coco.json") |> list_c()

# Detections --------------------------------------------------------------

# Create an empty dataframe to be grown
detections <- data.frame()

for (file in file_list) {

  # print(file)

  outls <- jsonlite::fromJSON(file, flatten = T)$annotations

  detections <- rbind(detections, janitor::clean_names(outls))

}

saveRDS(detections, "data/detections.rds")
