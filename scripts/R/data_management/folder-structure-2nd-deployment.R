library(readxl)
library(magrittr)
library(dplyr)
library(tidyr)

deps <- read_excel("data-raw/RoF_CameraDeploymentLog.xlsx")

folders <- list.files("/media/vlucet/My Passport/Images/")
folders

deps_filt <- deps %>%
  filter(`Camera ID` %in% folders)
stopifnot(nrow(deps_filt) == length(folders))

for (plot_id in unique(deps_filt$PlotID)) {

  print(plot_id)

  dir.create(paste0("/media/vlucet/My Passport/Images/", plot_id))

  plot_dat <- deps_filt %>%
    filter(PlotID == plot_id)

  for (site_id in unique(plot_dat$SiteID)) {

    dir.create(paste0("/media/vlucet/My Passport/Images/", plot_id, "/", site_id))

  }

}

deps_filt %>% arrange(`Camera ID`, PlotID, SiteID) %>% View()
