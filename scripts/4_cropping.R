library(magrittr)

# -------------------------------------------------------------------------

anns_wide_noempty <- readRDS(
  "analysis/data/derived_data/annotations_wide_noempty.rds") %>%
  dplyr::mutate(crop_name = NA)

out_folder <- "/media/vlucet/TrailCamST/Cropped/"
base_folder <- "/media/vlucet/TrailCamST/TrailCamStorage/"

make_crop_name <- function(r, out_folder = "/media/vlucet/TrailCamST/Cropped/") {

  if (is.na(r$value_rectanglelabels)){
    stopifnot(!is.na(r$species))
    if (r$species %in% c("Human", "Vehicle")) {
      mid_path <- paste0("TRUE/Other/", r$species, "_")
    } else {
      mid_path <- paste0("TRUE/Animal/", paste(r$species, collapse = "_"), "_")
    }
  } else {
    if (r$value_rectanglelabels == "animal") {
      mid_path <- "FP/Animal/animal_"
    } else {
      mid_path <- paste0("FP/Other/", r$value_rectanglelabels, "_")
    }
  }

  img_name <- paste0(out_folder, mid_path,
                     r$id,".JPG")
  return(img_name)
}

for (row in seq_len(nrow(anns_wide_noempty))){

  r <- anns_wide_noempty[row,]
  img_name <- make_crop_name(r)
  anns_wide_noempty[row,"crop_name"] <- img_name

  if (file.exists(img_name)) {

    next

  } else {

    print(r$id)

    img <- magick::image_read(paste0(base_folder, r$source_file))
    img_cropped <- image_crop(img, magick::geometry_area(
      width = (r$value_width/100)*r$original_width,
      height = (r$value_height/100)*r$original_height,
      x_off = (r$value_x/100)*r$original_width,
      y_off = (r$value_y/100)*r$original_height))

    magick::image_write(img_cropped, img_name)

    image_destroy(img)
    image_destroy(img_cropped)
    gc()

  }

}

saveRDS(anns_wide_noempty, "analysis/data/derived_data/annotations_wide_noempty_with_crop.rds")

# -------------------------------------------------------------------------

anns_wide_noempty_wc <- readRDS(
  "analysis/data/derived_data/annotations_wide_noempty_with_crop.rds")

get_hue <- function(crop_name){

  img <- imager::load.image(crop_name)

  if (length(imager::channels(img)) == 3) {
    return(mean(as.data.frame(imager::RGBtoHSV(img), wide="c")$c.1,
                na.rm = TRUE))
  } else {
    return(NA)
  }

}

get_greenness <- function(crop_name){

  img <- imager::load.image(crop_name)

  if (length(imager::channels(img)) == 3) {
    hue <- as.data.frame(imager::RGBtoHSV(img), wide="c")$c.1
    hue_pct <- length(hue[hue >= 125 & hue <= 175])/length(hue)
    return(hue_pct)
  } else {
    return(NA)
  }

}

get_greenness_rgb <- function(crop_name){

  img <- imager::load.image(crop_name)

  if (length(imager::channels(img)) == 3) {
    # browser()
    rgb <- colSums(as.data.frame(img, wide = "c"))
    gr <- rgb["c.1"]/sum(c(rgb["c.2"],rgb["c.3"]))
    return(gr)
  } else {
    return(NA)
  }

}

anns_wide_noempty_wc_sp <- anns_wide_noempty_wc %>%
  # dplyr::slice_sample(n=1000) %>%
  # dplyr::slice(1:10) %>%
  dplyr::mutate(greenness_rgb = sapply(crop_name, get_greenness_rgb),
                greenness = sapply(crop_name, get_greenness),
                mean_HUE = sapply(crop_name, get_hue),
                size = value_width*value_height) %>%
  dplyr::mutate(is_TP = is.na(value_rectanglelabels))
anns_wide_noempty_wc_sp$is_TP <- as.factor(anns_wide_noempty_wc_sp$is_TP)

saveRDS(anns_wide_noempty_wc_sp, "analysis/data/derived_data/anns_wide_noempty_wc_sp.rds")
anns_wide_noempty_wc_sp <- readRDS("analysis/data/derived_data/anns_wide_noempty_wc_sp.rds") %>%
  dplyr::filter(!is.na(mean_HUE))

anov <- aov(greenness_rgb~is_TP, data = anns_wide_noempty_wc_sp)
summary(anov)
anov <- aov(greenness~is_TP, data = anns_wide_noempty_wc_sp) # no
summary(anov)
anov <- aov(mean_HUE~is_TP, data = anns_wide_noempty_wc_sp)
summary(anov)
anov <- aov(size~is_TP, data = anns_wide_noempty_wc_sp)
summary(anov)

ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=is_TP, y=greenness_rgb))+
  ggplot2::geom_violin()
ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=is_TP, y=greenness))+
  ggplot2::geom_violin()
ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=is_TP, y=mean_HUE))+
  ggplot2::geom_violin()
ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=is_TP, y=size))+
  ggplot2::geom_violin()

ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=is_TP, y=greenness_rgb))+
  ggplot2::geom_boxplot()
ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=is_TP, y=greenness))+
  ggplot2::geom_boxplot()
ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=is_TP, y=mean_HUE))+
  ggplot2::geom_boxplot()
ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=is_TP, y=size))+
  ggplot2::geom_boxplot()

for (row in seq_len(nrow(anns_wide_noempty_wc))){

  r <- anns_wide_noempty_wc[row,]
  img <- imager::load.image(r$crop_name)

  if (length(imager::channels(img)) == 3) {

    anns_wide_noempty_wc[row,"mean_HUE"] <-
      mean(as.data.frame(imager::RGBtoHSV(img), wide="c")$c.1, na.rm = TRUE)
  }

  gc()
}

ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=size, y=mean_HUE, color=is_TP))+
  ggplot2::geom_point()

ggplot2::ggplot(anns_wide_noempty_wc_sp,
                ggplot2::aes(x=size, y=greenness, color=is_TP))+
  ggplot2::geom_point()

# -------------------------------------------------------------------------

m1 <- mgcv::gam(is_TP~s(size)+s(mean_HUE), family = binomial,
                data=anns_wide_noempty_wc_sp)
summary(m1)

library(tidymodels)

set.seed(123)
trees_split <- initial_split(anns_wide_noempty_wc_sp, strata = is_TP)
trees_train <- training(trees_split)
trees_test <- testing(trees_split)

tree_rec <- recipe(is_TP~size+mean_HUE+id, data = trees_train) %>%
  update_role(id, new_role = "id variable") # %>%
# step_other(species, caretaker, threshold = 0.01) %>%
# step_other(site_info, threshold = 0.005) %>%
# step_dummy(all_nominal(), -all_outcomes()) %>%
# step_date(date, features = c("year")) %>%
# step_rm(date) %>%
# step_downsample(legal_status)

tree_prep <- prep(tree_rec)
juiced <- juice(tree_prep)

tune_spec <- rand_forest(
  mtry = tune(),
  trees = 1000,
  min_n = tune()
) %>%
  set_mode("classification") %>%
  set_engine("ranger")

tune_wf <- workflow() %>%
  add_recipe(tree_rec) %>%
  add_model(tune_spec)

set.seed(234)
trees_folds <- vfold_cv(trees_train)

doParallel::registerDoParallel()

set.seed(345)
tune_res <- tune_grid(
  tune_wf,
  resamples = trees_folds,
  grid = 20
)

tune_res

tune_res %>%
  collect_metrics() %>%
  filter(.metric == "roc_auc") %>%
  select(mean, min_n, mtry) %>%
  pivot_longer(min_n:mtry,
               values_to = "value",
               names_to = "parameter"
  ) %>%
  ggplot(aes(value, mean, color = parameter)) +
  geom_point(show.legend = FALSE) +
  facet_wrap(~parameter, scales = "free_x") +
  labs(x = NULL, y = "AUC")

rf_grid <- grid_regular(
  mtry(range = c(10, 30)),
  min_n(range = c(2, 8)),
  levels = 5
)

rf_grid

set.seed(456)
regular_res <- tune_grid(
  tune_wf,
  resamples = trees_folds,
  grid = rf_grid
)

regular_res

regular_res %>%
  collect_metrics() %>%
  filter(.metric == "roc_auc") %>%
  mutate(min_n = factor(min_n)) %>%
  ggplot(aes(mtry, mean, color = min_n)) +
  geom_line(alpha = 0.5, size = 1.5) +
  geom_point() +
  labs(y = "AUC")

best_auc <- select_best(regular_res, "roc_auc")

final_rf <- finalize_model(
  tune_spec,
  best_auc
)

final_rf

library(vip)

final_rf %>%
  set_engine("ranger", importance = "permutation") %>%
  fit(is_TP~size+mean_HUE,
      data = juice(tree_prep) %>% select(-id)
  ) %>%
  vip(geom = "point")

final_wf <- workflow() %>%
  add_recipe(tree_rec) %>%
  add_model(final_rf)

final_res <- final_wf %>%
  last_fit(trees_split)

final_res %>%
  collect_metrics()

final_res %>%
  collect_predictions() %>%
  mutate(correct = case_when(
    is_TP == .pred_class ~ "Correct",
    TRUE ~ "Incorrect"
  )) %>%
  bind_cols(trees_test) %>%
  ggplot(aes(x=size, y=mean_HUE, color = correct)) +
  geom_point(size = 0.5, alpha = 0.5) +
  labs(color = NULL) +
  scale_color_manual(values = c("gray80", "darkred"))

# -------------------------------------------------------------------------

# read in old and new 58
library(magrittr)

old <- readr::read_csv("old_58.csv") %>%
  dplyr::mutate(from = "old")
# new <- readr::read_csv("new_58.csv") %>%
#   dplyr::mutate(from = "new")

# row_sums <- nrow(old) + nrow(new)

# full <- old %>% dplyr::full_join(new)

old <- old %>%
  dplyr::mutate(value_rectanglelabels =
                  stringr::str_remove(value_rectanglelabels,
                                      stringr::fixed("['"))) %>%
  dplyr::mutate(value_rectanglelabels =
                  stringr::str_remove(value_rectanglelabels,
                                      stringr::fixed("']"))) |>
  dplyr::select(-type) |>
  dplyr::mutate(manual = stringr::str_detect(id, "_M")) |>
  dplyr::mutate(image_id = stringr::str_split(id, "_")) |>
  dplyr::mutate(image_id =
                  unlist(purrr::map(image_id,
                                    ~paste0(.x[1:5], collapse = "_")))) |>
  tidyr::pivot_wider(names_from = "variable", values_from = "tag") |>
  dplyr::filter(is.na(value_text)) |>
  dplyr::mutate (species = ifelse(species == 'Other [See more species]',
                                  other_species, species)) |>
  dplyr::select(-other_species)


# read in new json to get files
# new_58 <- jsonlite::fromJSON(txt = "new_58.json",
#                              simplifyVector = F,
#                              flatten = F)
# names(new_58) <- unlist(lapply(new_58, function(x){unlist(x$data$image)}))
#
# all_files <-
#   stringr::str_replace(names(new_58), pattern = stringr::fixed("data/local-files/?d=TrailCamStorage/"),
#                        replacement = "")
#
# join_df <- data.frame(source_file = all_files)


no_rep <- jsonlite::fromJSON(txt = "/media/vlucet/TrailCamST/culling/P058_culled_for_ls_norepeats.json",
                             simplifyVector = T,
                             flatten = T)


for (row_id in 1:nrow(no_rep)){

  r <- no_rep[row_id, ]
  pred <- r$predictions

  id (is.null(pred$result)){
    next
  } else {




  }


}







































