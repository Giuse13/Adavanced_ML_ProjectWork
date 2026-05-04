source("project/config.R")

paths <- project_paths

required_packages <- c("ggplot2", "ggraph", "igraph", "patchwork", "ragg", "systemfonts")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop("Pacchetti R mancanti: ", paste(missing_packages, collapse = ", "))
}

library(ggplot2)
library(ggraph)
library(igraph)
library(patchwork)

slides_dir <- "slides"
slides_figures_dir <- file.path(slides_dir, "figures")
slides_fonts_dir <- file.path(slides_dir, "fonts")

aic_plot_output_path <- file.path(slides_figures_dir, "dag_hill_climbing_aic.png")
bic_plot_output_path <- file.path(slides_figures_dir, "dag_hill_climbing_bic.png")

required_paths <- c(
  paths$dag_arcs_path,
  paths$dag_bic_arcs_path,
  paths$dag_markov_blanket_selected_vars_path,
  paths$dag_bic_markov_blanket_selected_vars_path
)

for (required_path in required_paths) {
  if (!file.exists(required_path)) {
    stop("File richiesto non trovato: ", required_path)
  }
}

dir.create(slides_figures_dir, recursive = TRUE, showWarnings = FALSE)

background_color <- "#fbf6f1"
primary_color <- "#20b48c"
secondary_color <- "#a9dfd0"
accent_color <- "#0f6d58"
muted_node_color <- "#f1e7de"
muted_edge_color <- "#cfc5bd"
grid_color <- "#e2d8d0"
text_color <- "#000000"
font_family <- "Raleway"
slide_width_px <- 1920
slide_height_px <- 1080
slide_dpi <- 160

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

read_selected_variables <- function(path) {
  setdiff(read.csv(path, stringsAsFactors = FALSE)$variable, "Diabetes_binary")
}

build_dag_graph <- function(arcs_path, selected_variables) {
  arcs <- read.csv(arcs_path, stringsAsFactors = FALSE)
  graph <- graph_from_data_frame(arcs, directed = TRUE)

  V(graph)$node_group <- ifelse(
    V(graph)$name == "Diabetes_binary",
    "Target",
    ifelse(V(graph)$name %in% selected_variables, "Markov blanket", "Other variables")
  )
  V(graph)$node_label <- format_node_label(V(graph)$name)
  V(graph)$node_fontface <- ifelse(V(graph)$name == "Diabetes_binary", "bold", "plain")
  V(graph)$node_size <- ifelse(
    V(graph)$node_group == "Target",
    13.5,
    ifelse(V(graph)$node_group == "Markov blanket", 10.2, 7.7)
  )

  edge_ends <- ends(graph, E(graph), names = TRUE)
  touches_target <- edge_ends[, 1] == "Diabetes_binary" | edge_ends[, 2] == "Diabetes_binary"
  touches_markov_blanket <- edge_ends[, 1] %in% selected_variables | edge_ends[, 2] %in% selected_variables

  E(graph)$edge_group <- ifelse(
    touches_target,
    "Direct target arc",
    ifelse(touches_markov_blanket, "Markov blanket neighborhood", "Other dependency")
  )
  E(graph)$edge_width <- ifelse(E(graph)$edge_group == "Direct target arc", 0.78, 0.42)
  E(graph)$edge_alpha <- ifelse(
    E(graph)$edge_group == "Other dependency",
    0.20,
    ifelse(E(graph)$edge_group == "Markov blanket neighborhood", 0.46, 0.88)
  )

  graph
}

create_dag_plot <- function(graph) {
  ggraph(graph, layout = "stress") +
    geom_edge_link(
      aes(edge_colour = edge_group, edge_alpha = edge_alpha, edge_width = edge_width),
      arrow = arrow(length = unit(2.6, "mm"), type = "closed"),
      end_cap = circle(5.0, "mm"),
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
      size = 4.05,
      lineheight = 0.86,
      repel = TRUE,
      max.overlaps = Inf,
      box.padding = 0.34,
      point.padding = 0.26,
      min.segment.length = 0,
      segment.color = grid_color,
      segment.size = 0.16,
      show.legend = FALSE
    ) +
    scale_fill_manual(
      values = c(
        "Target" = primary_color,
        "Markov blanket" = secondary_color,
        "Other variables" = muted_node_color
      )
    ) +
    scale_edge_colour_manual(
      values = c(
        "Direct target arc" = primary_color,
        "Markov blanket neighborhood" = accent_color,
        "Other dependency" = muted_edge_color
      )
    ) +
    scale_edge_width_identity() +
    scale_edge_alpha_identity() +
    scale_color_manual(
      values = c(
        "Target" = text_color,
        "Markov blanket" = text_color,
        "Other variables" = text_color
      )
    ) +
    scale_size_identity() +
    theme_void(base_family = font_family) +
    theme(
      plot.background = element_rect(fill = background_color, color = NA),
      panel.background = element_rect(fill = background_color, color = NA),
      plot.margin = margin(0, 56, 0, 56)
    )
}

aic_selected_variables <- read_selected_variables(paths$dag_markov_blanket_selected_vars_path)
bic_selected_variables <- read_selected_variables(paths$dag_bic_markov_blanket_selected_vars_path)

aic_graph <- build_dag_graph(paths$dag_arcs_path, aic_selected_variables)
bic_graph <- build_dag_graph(paths$dag_bic_arcs_path, bic_selected_variables)

aic_plot <- create_dag_plot(aic_graph)
bic_plot <- create_dag_plot(bic_graph)

legend_data <- data.frame(
  x = c(1, 2, 3),
  y = c(1, 1, 1),
  label = c("Target", "Markov blanket", "Altre variabili"),
  group = factor(c("Target", "Markov blanket", "Other variables"), levels = c("Target", "Markov blanket", "Other variables"))
)

legend_plot <- ggplot(legend_data, aes(x = x, y = y)) +
  geom_point(aes(fill = group), shape = 21, size = 6.5, color = accent_color, stroke = 0.42) +
  geom_text(aes(label = label), family = font_family, size = 4.2, hjust = 0, nudge_x = 0.10) +
  scale_fill_manual(
    values = c(
      "Target" = primary_color,
      "Markov blanket" = secondary_color,
      "Other variables" = muted_node_color
    )
  ) +
  coord_cartesian(xlim = c(0.75, 3.95), ylim = c(0.86, 1.14), clip = "off") +
  theme_void(base_family = font_family) +
  theme(
    legend.position = "none",
    plot.background = element_rect(fill = background_color, color = NA),
    panel.background = element_rect(fill = background_color, color = NA),
    plot.margin = margin(0, 0, 0, 0)
  )

create_slide_plot <- function(dag_plot, slide_title, slide_subtitle) {
  dag_plot /
    legend_plot +
    plot_layout(heights = c(1, 0.06)) +
  plot_annotation(
    title = slide_title,
    subtitle = slide_subtitle,
    caption = "Gli archi indicano dipendenze dirette nella rete bayesiana appresa; i nodi evidenziati appartengono alla Markov blanket del target.",
    theme = theme(
      plot.background = element_rect(fill = background_color, color = NA),
      plot.title = element_text(
        family = font_family,
        color = text_color,
        size = 34,
        face = "bold",
        hjust = 0.5,
        margin = margin(t = 28, b = 6)
      ),
      plot.subtitle = element_text(
        family = font_family,
        color = text_color,
        size = 15,
        hjust = 0.5,
        margin = margin(b = 8)
      ),
      plot.caption = element_text(
        family = font_family,
        color = text_color,
        size = 10,
        hjust = 0.5,
        margin = margin(t = 4, b = 10)
      ),
      plot.margin = margin(0, 30, 0, 30)
    )
  )
}

aic_slide_plot <- create_slide_plot(
  aic_plot,
  "DAG Hill Climbing - AIC",
  paste0(
    gsize(aic_graph),
    " archi, ",
    length(aic_selected_variables),
    " variabili nella Markov blanket. Struttura piu' densa attorno a Diabetes_binary."
  )
)

bic_slide_plot <- create_slide_plot(
  bic_plot,
  "DAG Hill Climbing - BIC",
  paste0(
    gsize(bic_graph),
    " archi, ",
    length(bic_selected_variables),
    " variabili nella Markov blanket. Struttura piu' parsimoniosa delle dipendenze condizionate."
  )
)

ggsave(
  filename = aic_plot_output_path,
  plot = aic_slide_plot,
  device = ragg::agg_png,
  width = slide_width_px,
  height = slide_height_px,
  units = "px",
  dpi = slide_dpi,
  bg = background_color
)

ggsave(
  filename = bic_plot_output_path,
  plot = bic_slide_plot,
  device = ragg::agg_png,
  width = slide_width_px,
  height = slide_height_px,
  units = "px",
  dpi = slide_dpi,
  bg = background_color
)

cat("Grafico DAG AIC salvato in:", aic_plot_output_path, "\n")
cat("Grafico DAG BIC salvato in:", bic_plot_output_path, "\n")
