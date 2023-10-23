library(magrittr)

old <- readr::read_csv("analysis/data/raw_data/label_studio_outputs/culled_post_test/old_128.csv") %>%
 dplyr::mutate(from = "old")
new <- readr::read_csv("analysis/data/raw_data/label_studio_outputs/culled_post_test/new_128.csv") %>%
 dplyr::mutate(from = "new")

row_sums <- nrow(old) + nrow(new)

# full <- old %>% dplyr::full_join(new)

full <- dplyr::bind_rows(old,new)

nrow(full) == row_sums

length(unique(full$source_file))

full %>% janitor::get_dupes(id) %>% View()

full %>% dplyr::filter(id %in% old$id[which(old$id %in% new$id)]) %>% View()
