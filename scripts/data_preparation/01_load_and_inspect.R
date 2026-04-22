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
  upper_triangle_values <- correlation_matrix[upper.tri(correlation_matrix)]
  thresholds <- c(0.3, 0.4, 0.5, 0.6)
  correlation_pairs <- as.data.frame(as.table(correlation_matrix))
  names(correlation_pairs) <- c("Variable_1", "Variable_2", "Correlation")
  correlation_pairs <- correlation_pairs[correlation_pairs$Variable_1 != correlation_pairs$Variable_2, ]
  correlation_pairs <- correlation_pairs[as.character(correlation_pairs$Variable_1) < as.character(correlation_pairs$Variable_2), ]
  strong_pairs <- correlation_pairs[abs(correlation_pairs$Correlation) > 0.3, ]
  strong_pairs <- strong_pairs[order(-abs(strong_pairs$Correlation)), ]

  cat("\nConteggio delle correlazioni sopra soglia:\n")
  for (threshold in thresholds) {
    count_above_threshold <- sum(abs(upper_triangle_values) > threshold, na.rm = TRUE)
    cat("Numero di correlazioni con coeff >", threshold, "e':", count_above_threshold, "\n")
  }

  cat("\nCoppie di variabili con correlazione maggiore di 0.3 in valore assoluto:\n")
  if (nrow(strong_pairs) == 0) {
    cat("Nessuna coppia con correlazione maggiore di 0.3.\n")
  } else {
    for (row_index in seq_len(nrow(strong_pairs))) {
      cat(
        as.character(strong_pairs$Variable_1[row_index]), "<->",
        as.character(strong_pairs$Variable_2[row_index]),
        ": coefficiente =", sprintf("%.3f", strong_pairs$Correlation[row_index]), "\n"
      )
    }
  }

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

