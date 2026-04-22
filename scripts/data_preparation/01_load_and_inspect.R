raw_data_path <- "data/raw/diabetes_binary_5050split_health_indicators_BRFSS2015.csv"
correlation_plot_path <- "reports/figures/correlation_heatmap.png"

if (!file.exists(raw_data_path)) {
  stop("Dataset non trovato in: ", raw_data_path)
}

library(ggplot2)

data <- read.csv(raw_data_path)
numeric_data <- data[sapply(data, is.numeric)]
na_count_per_variable <- colSums(is.na(data))

cat("Dimensioni dataset:", nrow(data), "righe x", ncol(data), "colonne\n")
cat("colonne:\n")
print(names(data))
cat("\nStruttura:\n")
str(data)
cat("\nNumero di NA per variabile:\n")
print(na_count_per_variable)

if (ncol(numeric_data) < 2) {
  cat("\nVariabili numeriche insufficienti per calcolare la matrice di correlazione.\n")
} else {
  correlation_matrix <- cor(numeric_data, use = "pairwise.complete.obs")

  cat("\nMatrice di correlazione tra variabili numeriche:\n")
  print(round(correlation_matrix, 3))

  dir.create(dirname(correlation_plot_path), recursive = TRUE, showWarnings = FALSE)

  correlation_df <- as.data.frame(as.table(correlation_matrix))
  names(correlation_df) <- c("Var1", "Var2", "Correlation")

  correlation_plot <- ggplot(correlation_df, aes(x = Var1, y = Var2, fill = Correlation)) +
    geom_tile(color = "white", linewidth = 0.4) +
    scale_fill_gradient2(
      low = "#1f4e79",
      mid = "#f7f7f7",
      high = "#a61c3c",
      midpoint = 0,
      limits = c(-1, 1),
      breaks = seq(-1, 1, by = 0.25),
      name = "Correlazione"
    ) +
    coord_fixed() +
    labs(
      title = "Heatmap delle correlazioni tra variabili numeriche",
      subtitle = "Dataset: diabetes_binary_5050split_health_indicators_BRFSS2015",
      x = NULL,
      y = NULL
    ) +
    theme_minimal(base_size = 14) +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 11),
      axis.text.y = element_text(size = 11),
      panel.grid = element_blank(),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA),
      plot.title = element_text(face = "bold", size = 18),
      plot.subtitle = element_text(size = 12, margin = margin(b = 12)),
      legend.title = element_text(size = 12, face = "bold"),
      legend.text = element_text(size = 10)
    )

  ggsave(
    filename = correlation_plot_path,
    plot = correlation_plot,
    width = 14,
    height = 12,
    dpi = 300
  )

  cat("\nHeatmap salvata in:", correlation_plot_path, "\n")
}
