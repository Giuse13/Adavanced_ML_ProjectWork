source("project/config.R")

paths <- project_paths

required_packages <- c("bnlearn", "ggplot2", "ggraph", "igraph", "patchwork", "ragg", "systemfonts")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop("Pacchetti R mancanti: ", paste(missing_packages, collapse = ", "))
}

library(ggplot2)
library(ggraph)
library(igraph)
library(patchwork)

slides_dir <- "slides"
slides_data_dir <- file.path(slides_dir, "data")
slides_figures_dir <- file.path(slides_dir, "figures")
slides_fonts_dir <- file.path(slides_dir, "fonts")

plot_output_path <- file.path(slides_figures_dir, "modeling_nb_tan_bic.png")
nb_arcs_output_path <- file.path(slides_data_dir, "naive_bayes_bic_arcs.csv")
tan_arcs_output_path <- file.path(slides_data_dir, "tan_bic_arcs.csv")

if (!file.exists(paths$bic_full_training_set_path)) {
  stop("Dataset BIC non trovato: ", paths$bic_full_training_set_path)
}

dir.create(slides_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(slides_figures_dir, recursive = TRUE, showWarnings = FALSE)

background_color <- "#fbf6f1"
primary_color <- "#20b48c"
secondary_color <- "#a9dfd0"
accent_color <- "#0f6d58"
muted_node_color <- "#f1e7de"
muted_edge_color <- "#b9aaa0"
text_color <- "#000000"
font_family <- "Raleway"
slide_width_px <- 1920
slide_height_px <- 1080
slide_dpi <- 160
target_variable <- "Diabetes_binary"

local_raleway_medium <- file.path(slides_fonts_dir, "Raleway", "static", "Raleway-Medium.ttf")
local_raleway_bold <- file.path(slides_fonts_dir, "Raleway", "static", "Raleway-Bold.ttf")

if (file.exists(local_raleway_medium) && file.exists(local_raleway_bold)) {
  systemfonts::register_font(
    name = font_family,
    plain = local_raleway_medium,
    bold = local_raleway_bold,
    italic = local_raleway_medium,
    bolditalic = local_raleway_bold
  )
} else {
  warning(
    "Font richiesti non trovati: ",
    local_raleway_medium,
    " / ",
    local_raleway_bold,
    ". Il device grafico usera' un fallback."
  )
}

label_map <- c(
  Diabetes_binary = "Diabetes\nbinary",
  BMI_categoriale = "BMI\ncateg.",
  MentHlth_categoriale = "MentHlth\ncateg.",
  PhysHlth_categoriale = "PhysHlth\ncateg.",
  HeartDiseaseorAttack = "Heart disease\nor attack",
  HvyAlcoholConsump = "Heavy\nalcohol",
  AnyHealthcare = "Healthcare",
  NoDocbcCost = "No doctor\nfor cost",
  PhysActivity = "Physical\nactivity",
  CholCheck = "Chol.\ncheck",
  HighChol = "High\nchol.",
  HighBP = "High\nBP",
  DiffWalk = "Diff.\nwalk"
)

format_node_label <- function(node_names) {
  mapped_labels <- label_map[node_names]
  ifelse(is.na(mapped_labels), node_names, mapped_labels)
}

prepare_bn_data <- function(data) {
  data[] <- lapply(data, factor)
  data
}

build_naive_bayes_structure <- function(data) {
  bnlearn::naive.bayes(
    x = data,
    training = target_variable
  )
}

build_tan_structure <- function(data) {
  bnlearn::tree.bayes(
    x = data,
    training = target_variable
  )
}

build_graph_from_bnlearn <- function(structure, model_type) {
  arcs <- as.data.frame(bnlearn::arcs(structure), stringsAsFactors = FALSE)
  names(arcs) <- c("from", "to")

  graph <- graph_from_data_frame(arcs, directed = TRUE)

  V(graph)$node_group <- ifelse(V(graph)$name == target_variable, "Target", "Predictor")
  V(graph)$node_label <- format_node_label(V(graph)$name)
  V(graph)$node_fontface <- ifelse(V(graph)$name == target_variable, "bold", "plain")
  V(graph)$node_size <- ifelse(V(graph)$node_group == "Target", 12.6, 8.8)

  edge_ends <- ends(graph, E(graph), names = TRUE)
  touches_target <- edge_ends[, 1] == target_variable | edge_ends[, 2] == target_variable

  E(graph)$edge_group <- ifelse(touches_target, "Target to predictor", "Covariate dependency")
  E(graph)$edge_width <- ifelse(E(graph)$edge_group == "Target to predictor", 0.78, 0.52)
  E(graph)$edge_alpha <- ifelse(model_type == "Naive Bayes", 0.52, ifelse(touches_target, 0.46, 0.82))

  list(graph = graph, arcs = arcs)
}

create_model_plot <- function(graph, title, subtitle) {
  ggraph(graph, layout = "stress") +
    geom_edge_link(
      aes(edge_colour = edge_group, edge_alpha = edge_alpha, edge_width = edge_width),
      arrow = arrow(length = unit(2.7, "mm"), type = "closed"),
      end_cap = circle(5.1, "mm"),
      start_cap = circle(4.2, "mm"),
      lineend = "round",
      show.legend = FALSE
    ) +
    geom_node_point(
      aes(fill = node_group, size = node_size),
      shape = 21,
      color = accent_color,
      stroke = 0.42,
      show.legend = FALSE
    ) +
    geom_node_text(
      aes(label = node_label, color = node_group, fontface = node_fontface),
      family = font_family,
      size = 3.8,
      lineheight = 0.86,
      repel = TRUE,
      max.overlaps = Inf,
      box.padding = 0.42,
      point.padding = 0.34,
      min.segment.length = 0,
      segment.color = muted_edge_color,
      segment.size = 0.14,
      show.legend = FALSE
    ) +
    scale_fill_manual(
      values = c(
        "Target" = primary_color,
        "Predictor" = secondary_color
      )
    ) +
    scale_color_manual(
      values = c(
        "Target" = text_color,
        "Predictor" = text_color
      )
    ) +
    scale_edge_colour_manual(
      values = c(
        "Target to predictor" = accent_color,
        "Covariate dependency" = primary_color
      )
    ) +
    scale_edge_width_identity() +
    scale_edge_alpha_identity() +
    scale_size_identity() +
    labs(
      title = title,
      subtitle = subtitle
    ) +
    theme_void(base_family = font_family) +
    theme(
      plot.background = element_rect(fill = background_color, color = NA),
      panel.background = element_rect(fill = background_color, color = NA),
      plot.title = element_text(color = text_color, size = 28, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(color = text_color, size = 13, hjust = 0.5, margin = margin(t = 4, b = 8)),
      plot.margin = margin(8, 48, 10, 48)
    )
}

create_text_panel <- function(title, bullets) {
  bullet_text <- paste(paste0("- ", bullets), collapse = "\n")

  ggplot() +
    annotate(
      "text",
      x = 0,
      y = 1,
      label = title,
      family = font_family,
      fontface = "bold",
      size = 6.0,
      color = text_color,
      hjust = 0,
      vjust = 1
    ) +
    annotate(
      "text",
      x = 0,
      y = 0.70,
      label = bullet_text,
      family = font_family,
      size = 4.4,
      lineheight = 1.10,
      color = text_color,
      hjust = 0,
      vjust = 1
    ) +
    coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), clip = "off") +
    theme_void(base_family = font_family) +
    theme(
      plot.background = element_rect(fill = background_color, color = NA),
      panel.background = element_rect(fill = background_color, color = NA),
      plot.margin = margin(0, 34, 0, 34)
    )
}

bic_data <- prepare_bn_data(read.csv(paths$bic_full_training_set_path, stringsAsFactors = TRUE))
predictor_count <- length(setdiff(names(bic_data), target_variable))

nb_structure <- build_naive_bayes_structure(bic_data)
tan_structure <- build_tan_structure(bic_data)

nb_result <- build_graph_from_bnlearn(nb_structure, "Naive Bayes")
tan_result <- build_graph_from_bnlearn(tan_structure, "TAN")

write.csv(nb_result$arcs, nb_arcs_output_path, row.names = FALSE)
write.csv(tan_result$arcs, tan_arcs_output_path, row.names = FALSE)

nb_plot <- create_model_plot(
  nb_result$graph,
  "Naive Bayes",
  paste0(gsize(nb_result$graph), " archi: il target e' padre di tutte le covariate")
)

tan_plot <- create_model_plot(
  tan_result$graph,
  "Tree-Augmented Naive Bayes",
  paste0(gsize(tan_result$graph), " archi: target + dipendenze ad albero tra covariate")
)

nb_text <- create_text_panel(
  "Assunzione principale",
  c(
    "predittori indipendenti condizionando su Diabetes_binary",
    "struttura fissata dal modello Naive Bayes",
    "parametri stimati con smoothing bayesiano"
  )
)

tan_text <- create_text_panel(
  "Estensione TAN",
  c(
    "mantiene Diabetes_binary come nodo centrale",
    "aggiunge dipendenze tra covariate",
    "struttura appresa tramite tree.bayes"
  )
)

slide_plot <- (
  nb_plot + tan_plot
) /
  (
    nb_text + tan_text
  ) +
  plot_layout(heights = c(1, 0.24)) +
  plot_annotation(
    caption = "NB e TAN sono stati addestrati anche negli scenari no selection e AIC; qui si mostra BIC per massimizzare la leggibilita' della struttura.",
    theme = theme(
      plot.background = element_rect(fill = background_color, color = NA),
      plot.caption = element_text(
        family = font_family,
        color = text_color,
        size = 9.6,
        hjust = 0.5,
        margin = margin(t = 4, b = 10)
      ),
      plot.margin = margin(24, 30, 0, 30)
    )
  )

ggsave(
  filename = plot_output_path,
  plot = slide_plot,
  device = ragg::agg_png,
  width = slide_width_px,
  height = slide_height_px,
  units = "px",
  dpi = slide_dpi,
  bg = background_color
)

cat("Slide NB/TAN salvata in:", plot_output_path, "\n")
cat("Archi Naive Bayes salvati in:", nb_arcs_output_path, "\n")
cat("Archi TAN salvati in:", tan_arcs_output_path, "\n")
