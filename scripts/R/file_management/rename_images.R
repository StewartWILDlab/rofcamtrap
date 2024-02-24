
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
