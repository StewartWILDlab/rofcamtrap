# Note: This takes the COCO formatted detections derived from the python tool
# mdtools, and outputs a table

# Folder with Megadetector detections in coco format
detections_folder <- "/media/vlucet/TrailCamST/TrailCamStorage/"

# List all the files with the proper file name format
file_list <- list.files(detections_folder, recursive = F,
                        full.names = T, pattern = "output_coco.json")

# Detections --------------------------------------------------------------

# Create an empty dataframe to be grown
detections <- data.frame()

for (file in file_list){

  # print(file)

  outls <- jsonlite::fromJSON(file, flatten = T)$annotations

  detections <- rbind(detections, janitor::clean_names(outls))

}

saveRDS(detections, "analysis/data/derived_data/detections.rds")
