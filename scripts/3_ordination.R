custom_rda_plot <- function(the_rda, sp_scale=2.3, clust=NA,
                            thres_plot=0.4,
                            scale_x_sp=0.8, scale_y_sp=0.6,
                            scale_x_bp=0.1, scale_y_bp=0.1) {

  mult <- # 1.7
    vegan::ordiArrowMul(vegan::scores(the_rda, display="bp", choices=c(1, 2),
                                      scaling=2))

  sc_si <- vegan::scores(the_rda, display="sites", choices=c(1,2), scaling=2) %>%
    as.data.frame() %>%
    tibble::rownames_to_column("name")
  sc_sp <- (vegan::scores(the_rda, display="species", choices=c(1,2), scaling=2) %>%
              as.data.frame() * sp_scale) %>%
    tibble::rownames_to_column("name") %>%
    dplyr::mutate(highlight =ifelse((abs(RDA1) > thres_plot | abs(RDA2) > thres_plot),
                                    name, ""))
  sc_bp <- (vegan::scores(the_rda, display="bp", choices=c(1, 2), scaling=2) %>%
              as.data.frame() * mult) %>%
    tibble::rownames_to_column("name")

  base <-  ggplot2::ggplot() +
    ggplot2::theme_bw() +
    ggplot2::coord_fixed(xlim = c(-1.5, 1.5)) +
    ggplot2::geom_hline(yintercept=0, lty = 3) +
    ggplot2::geom_vline(xintercept=0, lty = 3) +

    ggplot2::geom_point(data = sc_sp,
                        ggplot2::aes(x=RDA1, y=RDA2),
                        color = "coral4",
                        pch = 3) +

    ggplot2::geom_segment(data = sc_bp, color = "steelblue4",
                          arrow = ggplot2::arrow(
                            length = ggplot2::unit(0.010, "npc")),
                          ggplot2::aes(x=0, y=0,
                                       xend=RDA1, yend=RDA2)) +

    ggrepel::geom_text_repel(data = sc_bp,
                             ggplot2::aes(x=RDA1, y=RDA2, label = name),
                             family = "Poppins",
                             size = 2.5,
                             min.segment.length = 10,
                             seed = 77,
                             # direction = "both",
                             # arrow = arrow(length = unit(0.010, "npc")),
                             nudge_x = ifelse(sc_bp$RDA1 < 0,
                                              -scale_x_bp,scale_x_bp),
                             nudge_y = ifelse(sc_bp$RDA2 < 0,
                                              -scale_y_bp,scale_y_bp),
                             color = "steelblue4") +

    ggrepel::geom_text_repel(data = sc_sp,
                             ggplot2::aes(x=RDA1, y=RDA2, label = highlight),
                             family = "Poppins",
                             size = 3,
                             # min.segment.length = 0,
                             seed = 77,
                             box.padding = 1,
                             point.padding = 0.3,
                             max.overlaps = Inf,
                             # arrow = arrow(length = unit(0.010, "npc")),
                             nudge_x = ifelse(sc_sp$RDA1 < 0,
                                              -scale_x_sp,scale_x_sp),
                             nudge_y = ifelse(sc_sp$RDA2 < 0,
                                              -scale_y_sp,scale_y_sp),
                             color = "coral4")

  if (is.numeric(clust)){

    grps <- data.frame(name = names(clust),
                       grp = as.factor(clust))

    sc_si <- sc_si %>%
      dplyr::left_join(grps, by = "name")

    base <- base +
      ggplot2::geom_point(data = sc_si,
                         ggplot2::aes(x=RDA1, y=RDA2, color=grp),
                         alpha=0.3,
                         size = 1) +
      ggplot2::stat_ellipse(data = sc_si,
                            ggplot2::aes(x=RDA1, y=RDA2, color=grp)) +
      ggplot2::theme(legend.position = 'none')

  } else {
    base <- base +
      # ggplot2::geom_text(data = sc_si,
      #                    ggplot2::aes(x=RDA1, y=RDA2, label=name),
      #                    size = 1.8,
      #                    color = "grey50")
      ggplot2::geom_point(data = sc_si,
                          ggplot2::aes(x=RDA1, y=RDA2),
                          alpha=0.3,
                          size = 1)

  }

  return(base)
}
