source("project/config.R")

paths <- project_paths

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Il pacchetto 'ggplot2' non e' installato nell'ambiente del progetto.")
}

library(ggplot2)

slides_dir <- "slides"
slides_data_dir <- file.path(slides_dir, "data")
slides_figures_dir <- file.path(slides_dir, "figures")
slides_fonts_dir <- file.path(slides_dir, "fonts")

summary_output_path <- file.path(
  slides_data_dir,
  "eda_shared_aic_bic_diabetes_percentages.csv"
)
plot_output_path <- file.path(
  slides_figures_dir,
  "eda_shared_aic_bic_diabetes_percentages.png"
)

required_paths <- c(
  paths$processed_data_path,
  paths$dag_markov_blanket_selected_vars_path,
  paths$dag_bic_markov_blanket_selected_vars_path
)

for (required_path in required_paths) {
  if (!file.exists(required_path)) {
    stop("File richiesto non trovato: ", required_path)
  }
}

dir.create(slides_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(slides_figures_dir, recursive = TRUE, showWarnings = FALSE)

background_color <- "#fbf6f1"
primary_color <- "#20b48c"
secondary_color <- "#a9dfd0"
grid_color <- "#ddd5ce"
text_color <- "#000000"
font_family <- "Raleway"
slide_width_px <- 1920
slide_height_px <- 1080
slide_dpi <- 160

local_raleway_medium <- file.path(slides_fonts_dir, "Raleway", "static", "Raleway-Medium.ttf")

if (
  requireNamespace("systemfonts", quietly = TRUE) &&
    file.exists(local_raleway_medium)
) {
  systemfonts::register_font(
    name = font_family,
    plain = local_raleway_medium,
    bold = local_raleway_medium,
    italic = local_raleway_medium,
    bolditalic = local_raleway_medium
  )
}

font_search_dirs <- c(
  slides_fonts_dir,
  "C:/Windows/Fonts",
  file.path(Sys.getenv("LOCALAPPDATA"), "Microsoft", "Windows", "Fonts")
)
font_search_dirs <- font_search_dirs[dir.exists(font_search_dirs)]
raleway_font_files <- unlist(lapply(
  font_search_dirs,
  function(font_dir) {
    list.files(font_dir, pattern = "Raleway", ignore.case = TRUE, full.names = TRUE)
  }
))

if (length(raleway_font_files) == 0) {
  warning(
    "Font Raleway non trovato tra i font installati. ",
    "Il grafico richiede family = 'Raleway', ma il device grafico potrebbe usare un fallback. ",
    "Metti i file .ttf in slides/fonts per rendere il risultato riproducibile."
  )
}

variable_priority <- c(
  "HighBP",
  "HighChol",
  "BMI_categoriale",
  "GenHlth",
  "Age",
  "DiffWalk",
  "HeartDiseaseorAttack",
  "Smoker",
  "HvyAlcoholConsump",
  "NoDocbcCost",
  "CholCheck",
  "AnyHealthcare"
)

variable_specs <- list(
  Age = list(
    facet_label = "Age",
    levels = as.character(1:13),
    display = c(
      "18-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54",
      "55-59", "60-64", "65-69", "70-74", "75-79", "80+"
    )
  ),
  AnyHealthcare = list(
    facet_label = "AnyHealthcare",
    levels = c("0", "1"),
    display = c("No", "Si")
  ),
  BMI_categoriale = list(
    facet_label = "BMIcategoriale",
    levels = c("sottopeso", "normopeso", "sovrappeso", "obesita"),
    display = c("Sottopeso", "Normopeso", "Sovrappeso", "Obesita")
  ),
  CholCheck = list(
    facet_label = "CholCheck",
    levels = c("0", "1"),
    display = c("No", "Si")
  ),
  DiffWalk = list(
    facet_label = "DiffWalk",
    levels = c("0", "1"),
    display = c("No", "Si")
  ),
  GenHlth = list(
    facet_label = "GenHlth",
    levels = c("1", "2", "3", "4", "5"),
    display = c("Excellent", "Very good", "Good", "Fair", "Poor")
  ),
  HeartDiseaseorAttack = list(
    facet_label = "HeartDiseaseorAttack",
    levels = c("0", "1"),
    display = c("No", "Si")
  ),
  HighBP = list(
    facet_label = "HighBP",
    levels = c("0", "1"),
    display = c("No", "Si")
  ),
  HighChol = list(
    facet_label = "HighChol",
    levels = c("0", "1"),
    display = c("No", "Si")
  ),
  HvyAlcoholConsump = list(
    facet_label = "HvyAlcoholConsump",
    levels = c("0", "1"),
    display = c("No", "Si")
  ),
  NoDocbcCost = list(
    facet_label = "NoDocbcCost",
    levels = c("0", "1"),
    display = c("No", "Si")
  ),
  Smoker = list(
    facet_label = "Smoker",
    levels = c("0", "1"),
    display = c("No", "Si")
  )
)

format_percent_label <- function(values) {
  paste0(format(round(values, 1), nsmall = 1, decimal.mark = "."), "%")
}

resolve_spec <- function(variable_name, observed_levels) {
  if (variable_name %in% names(variable_specs)) {
    variable_spec <- variable_specs[[variable_name]]
    matching_indices <- variable_spec$levels %in% observed_levels

    return(list(
      facet_label = variable_spec$facet_label,
      levels = variable_spec$levels[matching_indices],
      display = variable_spec$display[matching_indices]
    ))
  }

  sorted_levels <- sort(observed_levels)
  list(
    facet_label = variable_name,
    levels = sorted_levels,
    display = sorted_levels
  )
}

build_variable_summary <- function(dataset, variable_name) {
  variable_values <- as.character(dataset[[variable_name]])
  observed_levels <- unique(variable_values[!is.na(variable_values)])
  variable_spec <- resolve_spec(variable_name, observed_levels)

  result <- data.frame(
    variable = character(),
    facet_label = character(),
    level = character(),
    display_level = character(),
    total_n = integer(),
    diabetes_n = integer(),
    diabetes_percentage = numeric(),
    level_order = integer(),
    stringsAsFactors = FALSE
  )

  for (level_index in seq_along(variable_spec$levels)) {
    current_level <- variable_spec$levels[level_index]
    level_mask <- variable_values == current_level
    total_n <- sum(level_mask, na.rm = TRUE)
    diabetes_n <- sum(level_mask & dataset$Diabetes_binary == 1, na.rm = TRUE)

    if (total_n == 0) {
      next
    }

    result <- rbind(
      result,
      data.frame(
        variable = variable_name,
        facet_label = variable_spec$facet_label,
        level = current_level,
        display_level = variable_spec$display[level_index],
        total_n = total_n,
        diabetes_n = diabetes_n,
        diabetes_percentage = 100 * diabetes_n / total_n,
        level_order = level_index,
        stringsAsFactors = FALSE
      )
    )
  }

  result
}

data <- read.csv(paths$processed_data_path, stringsAsFactors = FALSE)

aic_selected_variables <- read.csv(
  paths$dag_markov_blanket_selected_vars_path,
  stringsAsFactors = FALSE
)$variable

bic_selected_variables <- read.csv(
  paths$dag_bic_markov_blanket_selected_vars_path,
  stringsAsFactors = FALSE
)$variable

shared_variables <- setdiff(intersect(aic_selected_variables, bic_selected_variables), "Diabetes_binary")
shared_variables <- c(
  intersect(variable_priority, shared_variables),
  setdiff(shared_variables, variable_priority)
)

if (length(shared_variables) == 0) {
  stop("Nessuna variabile condivisa trovata tra le selezioni AIC e BIC.")
}

summary_list <- lapply(shared_variables, function(variable_name) {
  build_variable_summary(data, variable_name)
})

summary_data <- do.call(rbind, summary_list)
summary_data$variable <- factor(summary_data$variable, levels = shared_variables)
summary_data$facet_label <- factor(
  summary_data$facet_label,
  levels = unique(summary_data$facet_label)
)
summary_data$diabetes_percentage_label <- format_percent_label(summary_data$diabetes_percentage)

plot_levels <- character()

for (variable_name in shared_variables) {
  variable_rows <- summary_data[summary_data$variable == variable_name, ]
  variable_rows <- variable_rows[order(variable_rows$level_order), ]
  plot_levels <- c(
    plot_levels,
    rev(paste(variable_rows$facet_label, variable_rows$display_level, sep = "___"))
  )
}

summary_data$plot_key <- paste(summary_data$facet_label, summary_data$display_level, sep = "___")
summary_data$plot_key <- factor(summary_data$plot_key, levels = plot_levels)

summary_data <- summary_data[
  order(summary_data$variable, summary_data$level_order),
  c(
    "variable",
    "facet_label",
    "level",
    "display_level",
    "total_n",
    "diabetes_n",
    "diabetes_percentage"
  )
]

write.csv(summary_data, summary_output_path, row.names = FALSE)

plot_data <- summary_data
plot_data$plot_key <- factor(
  paste(plot_data$facet_label, plot_data$display_level, sep = "___"),
  levels = plot_levels
)
plot_data$facet_label <- factor(plot_data$facet_label, levels = unique(as.character(plot_data$facet_label)))
plot_data$diabetes_percentage_label <- format_percent_label(plot_data$diabetes_percentage)

shared_variables_count <- length(shared_variables)

eda_plot <- ggplot(
  plot_data,
  aes(x = diabetes_percentage, y = plot_key, fill = diabetes_percentage)
) +
  geom_col(
    width = 0.72,
    color = primary_color,
    linewidth = 0.25
  ) +
  geom_text(
    aes(label = diabetes_percentage_label),
    hjust = -0.10,
    size = 3.0,
    color = text_color
  ) +
  facet_wrap(~ facet_label, scales = "free_y", ncol = 4) +
  scale_fill_gradient(
    low = secondary_color,
    high = primary_color,
    guide = "none"
  ) +
  scale_y_discrete(labels = function(values) sub("^.*___", "", values)) +
  scale_x_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, by = 20),
    labels = function(values) paste0(values, "%"),
    expand = expansion(mult = c(0, 0.18))
  ) +
  labs(
    title = "Percentuale di diabetici per modalita'",
    subtitle = paste0(
      "Variabili condivise dalla Markov blanket AIC e BIC (n = ",
      shared_variables_count,
      ")"
    ),
    x = "Quota di osservazioni con Diabetes_binary = 1 nella modalita'",
    y = NULL,
    caption = paste(
      "Nota: percentuali calcolate sul dataset bilanciato 50/50.",
      "Non rappresentano la prevalenza nella popolazione generale."
    )
  ) +
  theme_minimal(base_size = 10, base_family = font_family) +
  theme(
    text = element_text(family = font_family, color = text_color),
    plot.background = element_rect(fill = background_color, color = NA),
    panel.background = element_rect(fill = background_color, color = NA),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = grid_color, linewidth = 0.35),
    strip.background = element_rect(fill = secondary_color, color = NA),
    strip.text = element_text(face = "bold", color = text_color, size = 9.5),
    axis.text.x = element_text(color = text_color, size = 7.8),
    axis.text.y = element_text(color = text_color, size = 7.4),
    axis.title.x = element_text(color = text_color, size = 8.8, margin = margin(t = 1)),
    plot.title = element_text(
      color = text_color,
      face = "bold",
      size = 30,
      hjust = 0.5,
      margin = margin(b = 5)
    ),
    plot.subtitle = element_text(color = text_color, size = 10, hjust = 0.5, margin = margin(b = 8)),
    plot.caption = element_text(color = text_color, size = 7.8, hjust = 0),
    plot.margin = margin(20, 18, 8, 12)
  )

ggsave(
  filename = plot_output_path,
  plot = eda_plot,
  device = if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png else "png",
  width = slide_width_px,
  height = slide_height_px,
  units = "px",
  dpi = slide_dpi,
  bg = background_color
)

cat("CSV riepilogativo salvato in:", summary_output_path, "\n")
cat("Grafico slide salvato in:", plot_output_path, "\n")
