required_packages <- c("ggplot2", "ragg", "systemfonts")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop("Pacchetti R mancanti: ", paste(missing_packages, collapse = ", "))
}

library(ggplot2)

slides_dir <- "slides"
slides_data_dir <- file.path(slides_dir, "data")
slides_figures_dir <- file.path(slides_dir, "figures")
slides_fonts_dir <- file.path(slides_dir, "fonts")

plot_output_path <- file.path(slides_figures_dir, "model_accuracy_interpretability_tradeoff.png")
data_output_path <- file.path(slides_data_dir, "accuracy_interpretability_tradeoff.csv")

dir.create(slides_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(slides_figures_dir, recursive = TRUE, showWarnings = FALSE)

background_color <- "#fbf6f1"
primary_color <- "#20b48c"
secondary_color <- "#a9dfd0"
accent_color <- "#0f6d58"
muted_color <- "#efe4dc"
line_color <- "#315f77"
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
    "Font Raleway non trovato in: ",
    slides_fonts_dir,
    ". Il device grafico usera' un fallback."
  )
}

model_data <- data.frame(
  model = c(
    "Deep learning",
    "Metodi ensemble",
    "Modelli statistici",
    "Modelli grafici",
    "K-nearest neighbors",
    "Alberi decisionali",
    "Regressione lineare/logistica",
    "Modelli rule-based"
  ),
  detail = c(
    "reti neurali",
    "BART, Random Forest",
    "SVM, regressioni",
    "BN, Markov blanket, DAG",
    "",
    "",
    "",
    ""
  ),
  interpretability = c(22, 35, 48, 58, 65, 72, 76, 78),
  accuracy = c(82, 79, 73, 66, 59, 48, 36, 28),
  label_x = c(22, 35, 48, 58, 65, 72, 76, 78) + c(2.3, 2.1, 2.1, 2.1, 2.0, 2.0, 2.0, 2.0),
  label_y = c(82, 79, 73, 66, 59, 48, 36, 28) + c(4.1, 2.2, 1.4, 0.8, 0.3, 0.1, -0.3, -0.3),
  stringsAsFactors = FALSE
)

model_data$label <- ifelse(
  model_data$detail == "",
  model_data$model,
  paste0(model_data$model, " (", model_data$detail, ")")
)


curve_data <- data.frame(
  interpretability = c(8, 18, model_data$interpretability, 80),
  accuracy = c(82, 82, model_data$accuracy, 10)
)

write.csv(model_data, data_output_path, row.names = FALSE)

tradeoff_plot <- ggplot() +
  annotate(
    "rect",
    xmin = -Inf,
    xmax = Inf,
    ymin = -Inf,
    ymax = Inf,
    fill = background_color
  ) +
  geom_path(
    data = curve_data,
    aes(x = interpretability, y = accuracy),
    color = line_color,
    linewidth = 0.75,
    linetype = "dotted",
    alpha = 0.95
  ) +
  geom_segment(
    aes(x = 8, y = 10, xend = 92, yend = 10),
    arrow = arrow(length = grid::unit(0.20, "inches"), type = "closed"),
    color = text_color,
    linewidth = 0.95
  ) +
  geom_segment(
    aes(x = 8, y = 10, xend = 8, yend = 92),
    arrow = arrow(length = grid::unit(0.20, "inches"), type = "closed"),
    color = text_color,
    linewidth = 0.95
  ) +
  geom_point(
    data = model_data,
    aes(x = interpretability, y = accuracy),
    shape = 21,
    size = 5.2,
    stroke = 1.9,
    fill = background_color,
    color = line_color
  ) +
  geom_point(
    data = model_data,
    aes(x = interpretability, y = accuracy),
    size = 1.4,
    color = text_color
  ) +
  geom_text(
    data = model_data,
    aes(x = label_x, y = label_y, label = label),
    family = font_family,
    size = 4.1,
    fontface = "bold",
    hjust = 0,
    color = text_color
  ) +
 
  annotate(
    "text",
    x = 50,
    y = 2.6,
    label = "Interpretabilita' del modello",
    family = font_family,
    fontface = "bold",
    size = 7.5,
    color = line_color
  ) +
  annotate(
    "text",
    x = 4.5,
    y = 51,
    label = "Accuratezza del modello",
    family = font_family,
    fontface = "bold",
    size = 7.5,
    angle = 90,
    color = line_color
  ) +
  coord_cartesian(xlim = c(0, 100), ylim = c(0, 100), clip = "off") +
  theme_void(base_family = font_family) +
  theme(
    plot.background = element_rect(fill = background_color, color = NA),
    panel.background = element_rect(fill = background_color, color = NA),
    plot.margin = margin(44, 76, 66, 76)
  )

ggsave(
  filename = plot_output_path,
  plot = tradeoff_plot,
  device = ragg::agg_png,
  width = slide_width_px,
  height = slide_height_px,
  units = "px",
  dpi = slide_dpi,
  bg = background_color
)

cat("Grafico accuracy/interpretabilita' salvato in:", plot_output_path, "\n")
cat("Dati salvati in:", data_output_path, "\n")
