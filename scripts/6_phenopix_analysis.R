library(phenopix)
library(raster)
library(magrittr)

# -------------------------------------------------------------------------

my.path <- structureFolder("~/Documents/Cropped/FP/Animal/")
img <- brick('~/Documents/Cropped/FP/Animal/REF/animal_P224-1_WLU-147_DCIM_104RECNX_RCNX4369_7.JPG')
img <- brick('~/Documents/Cropped/FP/Animal/animal_P028-1_WLU-10_DCIM_100RECNX_RCNX0148_6.JPG')
plotRGB(img)

plot(img[[1]])
plot(img[[2]])
plot(img[[3]])

DrawMULTIROI(path_img_ref = '~/Documents/Cropped/FP/Animal/REF/animal_P224-1_WLU-147_DCIM_104RECNX_RCNX4369_7.JPG',
             nroi = 1, path_ROIs = '~/Documents/Cropped/FP/Animal/REF/')

PrintROI(path_img_ref = '~/Documents/Cropped/FP/Animal/REF/animal_P224-1_WLU-147_DCIM_104RECNX_RCNX4369_7.JPG',
         path_ROIs = '~/Documents/Cropped/FP/Animal/REF/')

load('~/Documents/Cropped/FP/Animal/REF/roi.data.Rdata')

extractVIs(img.path = '~/Documents/Cropped/FP/Animal/IMG',file.type = ".JPG",
           date.code = 'yyyymmdd',
           roi.path = '~/Documents/Cropped/FP/Animal/REF/')

load("VI.data.Rdata")
VI.data

# -------------------------------------------------------------------------

base <- "/media/vlucet/TrailCamST/Cropped/"
all_files <- list.files(base, recursive = T)

library(exifr)
exif_df <- read_exif(file.path(base, all_files), tags = c("filename", "imagesize",  	"DateTimeOriginal"))
View(exif_df)

saveRDS(exif_df,"exif_df.rds")

exif_df <- readRDS("exif_df.rds")

collect_indices <- function(img, base = "/media/vlucet/TrailCamST/Cropped/"){

  # browser()
  img_brick <- brick(file.path(base, img))

  if(nlayers(img_brick) == 3) {

    img_split <- unlist(strsplit(img, "/"))
    status <- img_split[1]
    category <- img_split[2]
    file <- img_split[3]

    red <- values(img_brick[[1]])
    green <- values(img_brick[[2]])
    blue <- values(img_brick[[3]])
    rgb <- red + green + blue
    rb <- red + blue

    r.av <- mean(red, na.rm=TRUE)
    g.av <- mean(green, na.rm=TRUE)
    b.av <- mean(blue, na.rm=TRUE)
    r.sd <- sd(red, na.rm=TRUE)
    g.sd <- sd(green, na.rm=TRUE)
    b.sd <- sd(blue, na.rm=TRUE)
    bri.av <- mean(rgb, na.rm=TRUE)
    bri.sd <- sd(rgb, na.rm=TRUE)
    gi.av <- mean(green/rgb,na.rm=TRUE)###
    gi.sd <- sd(green/rgb,na.rm=TRUE)
    gei.av <- mean( 2*green - (rb),na.rm=TRUE)
    gei.sd <- sd( 2*green - (rb),na.rm=TRUE)
    ri.av <- mean(red/rgb,na.rm=TRUE)
    ri.sd <- sd(red/rgb,na.rm=TRUE)
    bi.av <- mean(blue/rgb,na.rm=TRUE)###
    bi.sd <- sd(blue/rgb,na.rm=TRUE)

    VI <- data.frame(status = status, category = category, file = file,
                     r.av = r.av, g.av = g.av, b.av = b.av,
                     r.sd = r.sd, g.sd = g.sd, b.sd = b.sd,
                     bri.av = bri.av, bri.sd = bri.sd, gi.av = gi.av,
                     gi.sd = gi.sd, gei.av = gei.av, gei.sd = gei.sd,
                     ri.av = ri.av, ri.sd = ri.sd, bi.av = bi.av, bi.sd = bi.sd)

    return(VI)
  }
}

test <- lapply(all_files, collect_indices)
test_df <- dplyr::bind_rows(test)

saveRDS(test_df,"test_df.rds")

test_df <- readRDS("test_df.rds")

joined <- dplyr::left_join(exif_df, test_df, by = c("FileName"="file")) %>%
  dplyr::mutate(date_time = lubridate::ymd_hms(DateTimeOriginal)) %>%
  dplyr::mutate(the_time = lubridate::hms(paste(lubridate::hour(date_time),
                                               lubridate::minute(date_time),
                                               lubridate::second(date_time)))) %>%
  dplyr::filter(the_time != 0) %>%
  dplyr::mutate(the_time_dt = lubridate::as_datetime(the_time)) %>%
  dplyr::mutate(the_time_numeric = as.numeric(the_time))

library(ggplot2)

for(var in names(test_df)[4:length(names(test_df))]){

  p <- ggplot(data=joined) +
    geom_point(aes(x=the_time_dt, y = .data[[var]],
                   color=status, shape = category),
               cex=0.2)
  print(p)
}

library(rpart)
library(rpart.plot)

m1 <- rpart(
  formula = status ~ .,
  data    = dplyr::select(joined, status, the_time_numeric, gi.av) %>%
    dplyr::filter(!is.na(status)) %>% as.data.frame()
)

rpart.plot(m1)

saveRDS(m1, "rpart_model.rds")

# -------------------------------------------------------------------------
# -------------------------------------------------------------------------

test_df[sample(1:nrow(test_df), 100),4:19] |> pairs()

cors <- test_df[,4:19] |> cor()
View(cors>0.5)

library(caret)

findCorrelation(cors)

test_df_clean <- test_df[,-(findCorrelation(cors)+3)]

test_df_long <- tidyr::pivot_longer(test_df_clean, cols = b.av:bi.sd) |>
  dplyr::mutate(comb = paste(status, category, sep = "_"))

library(ggplot2)

ggplot(test_df_long) +
  geom_boxplot(aes(y=value,color=status)) +
  facet_wrap(~name, scales = "free")

test_df_long_list <- test_df_long |> split.data.frame(test_df_long$name)

aovs <- lapply(test_df_long_list,
               function(x) (aov(formula = value~status,data = x)))

aovs

library(tidymodels)

test_df_rf <- test_df_clean |> dplyr::select(-category, -file)

set.seed(123)
trees_split <- initial_split(test_df_rf, strata = status)
trees_train <- training(trees_split)
trees_test <- testing(trees_split)

tree_rec <- recipe(status~., data = trees_train)# %>%
#  update_role(id, new_role = "id variable") # %>%
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
  trees = 100,
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
  grid = 10
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
  fit(status~.,
      data = juice(tree_prep)
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
    status == .pred_class ~ "Correct",
    TRUE ~ "Incorrect"
  )) %>%
  bind_cols(trees_test) %>%
  ggplot(aes(x=status, y=value, color = correct)) +
  geom_point(size = 0.5, alpha = 0.5) +
  labs(color = NULL) +
  scale_color_manual(values = c("gray80", "darkred"))

# -------------------------------------------------------------------------
