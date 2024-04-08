
# First deployment
rename_images(images_from = "/media/vlucet/TrailCamST1/TrailCamStorage",
              images_to = "/media/vlucet/TrailCamST1/renamed",
              deployment_code = "TC1",
              locations_subset = c(
                "Q647", "P216", "P100", "P087", "P058", "P045", "P293", "P080", "P224"
                ),  # "P352", "P132", "P128", "P121", "P030"
              file_ext = "\\.(jpg|jpeg|JPG|JPEG)$")

# Second deployment
rename_images(images_from = "/media/vlucet/TrailCamST1/TrailCamStorage_2/",
              images_to = "/media/vlucet/TrailCamST1/renamed",
              deployment_code = "TC2",
              file_ext = "\\.(jpg|jpeg|JPG|JPEG)$")

# [1] "P045" "P058" "P080!!!" "P087" "P100"
# [6] "P216" "P224" "P293" "Q647"

library(wildRtrax)

Sys.setenv(WT_USERNAME = 'valentin.lucet@gmail.com',
           WT_PASSWORD = 'FF3DhjsN9D$MMDn#')

# debugonce(wt_auth)
wt_auth(force = T)

# debugonce(wt_get_download_summary)
my_projects <- wt_get_download_summary(sensor_id = 'CAM')

# client <- httr2::oauth_client(
#   id = "Eg2MPVtqkf3SuKS5uXzP97nxU13Z2K1i",
#   token_url = "https://abmi.auth0.com/oauth/token",
#   name = "wildtrax"
# )

# debugonce(httr2::oauth_flow_password)
# tok <- httr2::oauth_flow_password(client = client, username = Sys.getenv("WT_USERNAME"),
#                            password = Sys.getenv("WT_PASSWORD"))

# -------------------------------------------------------------------------

# .wt_api_pr(path = "/bis/get-download-summary", sensorId = sensor_id,
#            sort = "fullNm", order = "asc")

debugonce(wt_download_report)
my_report <- wt_download_report(project_id = 2431, sensor_id = 'CAM', reports = "image_report", weather_cols = F) |>
  tibble::as_tibble()

my_report <- wt_download_report(project_id = 2431, sensor_id = 'CAM', reports = "main", weather_cols = F) |>
  tibble::as_tibble()
img_report <- wt_download_report(project_id = 2431, sensor_id = 'CAM', reports = "image_report", weather_cols = F) |>
  tibble::as_tibble()
md_report <- wt_download_report(project_id = 2431, sensor_id = 'CAM', reports = "megadetector", weather_cols = F) |>
  tibble::as_tibble()

saveRDS(my_report, "my_report.rds")
