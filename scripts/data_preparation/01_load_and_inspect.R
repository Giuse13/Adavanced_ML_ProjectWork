raw_data_path <- "data/raw/diabetes_binary_5050split_health_indicators_BRFSS2015.csv"
correlation_plot_path <- "reports/figures/correlations/correlation_heatmap.png"
distribution_plots_dir <- "reports/figures/distributions"
variable_modality_percentages_path <- "reports/results/variable_modality_percentages.xlsx"
binary_imbalanced_covariates_path <- "reports/results/binary_imbalanced_covariates.xlsx"

if (!file.exists(raw_data_path)) {
  stop("Dataset non trovato in: ", raw_data_path)
}

library(ggplot2)
library(openxlsx)

show_dataset_dimensions <- FALSE
show_variable_names <- FALSE
show_dataset_structure <- FALSE
show_na_count_per_variable <- FALSE
generate_distribution_plots <- FALSE
show_correlation_threshold_counts <- FALSE
show_strong_correlation_pairs <- FALSE
save_correlation_heatmap <- FALSE
report_variable_modality_percentages <- FALSE
export_binary_imbalanced_covariates <- FALSE


data <- read.csv(raw_data_path)
numeric_data <- data[sapply(data, is.numeric)]
na_count_per_variable <- colSums(is.na(data))

if (show_dataset_dimensions) {
  cat("Dimensioni dataset:", nrow(data), "righe x", ncol(data), "colonne\n")
}

if (show_variable_names) {
  cat("colonne:\n")
  print(names(data))
}

if (show_dataset_structure) {
  cat("\nStruttura:\n")
  str(data)
}

if (show_na_count_per_variable) {
  cat("\nNumero di NA per variabile:\n")
  print(na_count_per_variable)
}

if (generate_distribution_plots) {
  dir.create(distribution_plots_dir, recursive = TRUE, showWarnings = FALSE)

  for (variable_name in names(data)) {
    variable_data <- data[[variable_name]]
    plot_data <- data.frame(value = variable_data)
    unique_values <- unique(variable_data[!is.na(variable_data)])
    sanitized_name <- gsub("[^A-Za-z0-9_]+", "_", variable_name)
    output_path <- file.path(distribution_plots_dir, paste0(sanitized_name, "_distribution.png"))

    if (length(unique_values) <= 10) {
      distribution_plot <- ggplot(plot_data, aes(x = factor(value))) +
        geom_bar(fill = "#1f4e79", color = "white", linewidth = 0.3) +
        labs(
          title = paste("Distribuzione di", variable_name),
          x = variable_name,
          y = "Frequenza"
        ) +
        theme_minimal(base_size = 13) +
        theme(
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          panel.background = element_rect(fill = "white", color = NA),
          plot.background = element_rect(fill = "white", color = NA),
          plot.title = element_text(face = "bold", size = 16),
          axis.text.x = element_text(angle = 45, hjust = 1)
        )
    } else {
      distribution_plot <- ggplot(plot_data, aes(x = value)) +
        geom_histogram(bins = 30, fill = "#1f4e79", color = "white", linewidth = 0.3) +
        labs(
          title = paste("Distribuzione di", variable_name),
          x = variable_name,
          y = "Frequenza"
        ) +
        theme_minimal(base_size = 13) +
        theme(
          panel.grid.minor = element_blank(),
          panel.background = element_rect(fill = "white", color = NA),
          plot.background = element_rect(fill = "white", color = NA),
          plot.title = element_text(face = "bold", size = 16)
        )
    }

    ggsave(
      filename = output_path,
      plot = distribution_plot,
      width = 8,
      height = 6,
      dpi = 300
    )
  }

  cat("\nGrafici di distribuzione salvati in:", distribution_plots_dir, "\n")
}

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

  if (show_correlation_threshold_counts) {
    cat("\nConteggio delle correlazioni sopra soglia:\n")
    for (threshold in thresholds) {
      count_above_threshold <- sum(abs(upper_triangle_values) > threshold, na.rm = TRUE)
      cat("Numero di correlazioni con coeff >", threshold, "e':", count_above_threshold, "\n")
    }
  }

  if (show_strong_correlation_pairs) {
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
  }

  if (save_correlation_heatmap) {
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
}



# check variabili sbilanciate 

if (report_variable_modality_percentages) {
  modality_summary_output <- data.frame(
    variable = character(),
    modality = character(),
    frequency = integer(),
    percentage = numeric(),
    stringsAsFactors = FALSE
  )
  workbook <- createWorkbook()
  used_sheet_names <- character()

  build_sheet_name <- function(variable_name) {
    sanitized_name <- gsub("[\\[\\]\\*\\?/\\\\:]", "_", variable_name)
    sanitized_name <- substr(sanitized_name, 1, 31)

    if (!(sanitized_name %in% used_sheet_names)) {
      used_sheet_names <<- c(used_sheet_names, sanitized_name)
      return(sanitized_name)
    }

    suffix_index <- 1
    repeat {
      suffix <- paste0("_", suffix_index)
      candidate <- paste0(substr(sanitized_name, 1, 31 - nchar(suffix)), suffix)

      if (!(candidate %in% used_sheet_names)) {
        used_sheet_names <<- c(used_sheet_names, candidate)
        return(candidate)
      }

      suffix_index <- suffix_index + 1
    }
  }

  for (variable_name in names(data)) {
    frequency_table <- table(data[[variable_name]], useNA = "ifany")
    percentage_table <- prop.table(frequency_table) * 100
    variable_table <- data.frame(
      modality = names(frequency_table),
      frequency = as.integer(frequency_table),
      percentage = round(as.numeric(percentage_table), 2),
      stringsAsFactors = FALSE
    )
    variable_table$percentage_label <- sprintf("%.2f%%", variable_table$percentage)

    modality_summary_output <- rbind(
      modality_summary_output,
      data.frame(
        variable = variable_name,
        modality = variable_table$modality,
        frequency = variable_table$frequency,
        percentage = variable_table$percentage,
        stringsAsFactors = FALSE
      )
    )

    sheet_name <- build_sheet_name(variable_name)
    addWorksheet(workbook, sheetName = sheet_name, gridLines = FALSE)
    writeData(workbook, sheet = sheet_name, x = data.frame(Variable = variable_name), startRow = 1, colNames = TRUE)
    writeData(workbook, sheet = sheet_name, x = variable_table[, c("modality", "frequency", "percentage_label")], startRow = 3)
    setColWidths(workbook, sheet = sheet_name, cols = 1:3, widths = "auto")
  }

  dir.create(dirname(variable_modality_percentages_path), recursive = TRUE, showWarnings = FALSE)
  addWorksheet(workbook, sheetName = "Summary", gridLines = FALSE)
  writeData(workbook, sheet = "Summary", x = modality_summary_output, startRow = 1)
  setColWidths(workbook, sheet = "Summary", cols = 1:4, widths = "auto")
  saveWorkbook(workbook, file = variable_modality_percentages_path, overwrite = TRUE)
  cat("\nFile Excel delle percentuali per modalita' salvato in:", variable_modality_percentages_path, "\n")
}

binary_imbalanced_covariate_tables <- list()
binary_covariate_names <- setdiff(names(data), "Diabetes_binary")

for (covariate_name in binary_covariate_names) {
  covariate_values <- data[[covariate_name]]
  unique_modalities <- sort(unique(covariate_values[!is.na(covariate_values)]))

  if (length(unique_modalities) != 2) {
    next
  }

  modality_distribution <- prop.table(table(covariate_values, useNA = "no"))
  if (max(modality_distribution) <= 0.70) {
    next
  }

  contingency_table <- as.data.frame.matrix(
    table(covariate_values, data$Diabetes_binary, useNA = "no")
  )

  if (!("0" %in% names(contingency_table))) {
    contingency_table[["0"]] <- 0
  }

  if (!("1" %in% names(contingency_table))) {
    contingency_table[["1"]] <- 0
  }

  contingency_table <- contingency_table[, c("0", "1")]
  contingency_table$X_covariata <- rownames(contingency_table)
  contingency_table$N_totale <- contingency_table[["0"]] + contingency_table[["1"]]
  contingency_table$N_diabete_1 <- contingency_table[["1"]]
  contingency_table$N_no_diabete_0 <- contingency_table[["0"]]
  contingency_table$percentuale_diabete <- round(
    100 * contingency_table$N_diabete_1 / contingency_table$N_totale,
    2
  )

  binary_imbalanced_covariate_tables[[covariate_name]] <- contingency_table[
    ,
    c(
      "X_covariata",
      "N_totale",
      "N_diabete_1",
      "N_no_diabete_0",
      "percentuale_diabete"
    )
  ]
  rownames(binary_imbalanced_covariate_tables[[covariate_name]]) <- NULL
}

if (export_binary_imbalanced_covariates) {
  imbalanced_workbook <- createWorkbook()
  imbalanced_summary_output <- data.frame(
    covariate = character(),
    modality = character(),
    n_totale = integer(),
    n_diabete_1 = integer(),
    n_no_diabete_0 = integer(),
    percentuale_diabete = numeric(),
    stringsAsFactors = FALSE
  )
  used_sheet_names <- character()

  build_sheet_name <- function(variable_name) {
    sanitized_name <- gsub("[\\[\\]\\*\\?/\\\\:]", "_", variable_name)
    sanitized_name <- substr(sanitized_name, 1, 31)

    if (!(sanitized_name %in% used_sheet_names)) {
      used_sheet_names <<- c(used_sheet_names, sanitized_name)
      return(sanitized_name)
    }

    suffix_index <- 1
    repeat {
      suffix <- paste0("_", suffix_index)
      candidate <- paste0(substr(sanitized_name, 1, 31 - nchar(suffix)), suffix)

      if (!(candidate %in% used_sheet_names)) {
        used_sheet_names <<- c(used_sheet_names, candidate)
        return(candidate)
      }

      suffix_index <- suffix_index + 1
    }
  }

  for (covariate_name in names(binary_imbalanced_covariate_tables)) {
    covariate_table <- binary_imbalanced_covariate_tables[[covariate_name]]
    covariate_table$percentuale_diabete_label <- sprintf("%.2f%%", covariate_table$percentuale_diabete)

    imbalanced_summary_output <- rbind(
      imbalanced_summary_output,
      data.frame(
        covariate = covariate_name,
        modality = covariate_table$X_covariata,
        n_totale = covariate_table$N_totale,
        n_diabete_1 = covariate_table$N_diabete_1,
        n_no_diabete_0 = covariate_table$N_no_diabete_0,
        percentuale_diabete = covariate_table$percentuale_diabete,
        stringsAsFactors = FALSE
      )
    )

    sheet_name <- build_sheet_name(covariate_name)
    addWorksheet(imbalanced_workbook, sheetName = sheet_name, gridLines = FALSE)
    writeData(imbalanced_workbook, sheet = sheet_name, x = data.frame(Covariate = covariate_name), startRow = 1, colNames = TRUE)
    writeData(
      imbalanced_workbook,
      sheet = sheet_name,
      x = covariate_table[, c("X_covariata", "N_totale", "N_diabete_1", "N_no_diabete_0", "percentuale_diabete_label")],
      startRow = 3
    )
    setColWidths(imbalanced_workbook, sheet = sheet_name, cols = 1:5, widths = "auto")
  }

  dir.create(dirname(binary_imbalanced_covariates_path), recursive = TRUE, showWarnings = FALSE)
  addWorksheet(imbalanced_workbook, sheetName = "Summary", gridLines = FALSE)
  writeData(imbalanced_workbook, sheet = "Summary", x = imbalanced_summary_output, startRow = 1)
  setColWidths(imbalanced_workbook, sheet = "Summary", cols = 1:6, widths = "auto")
  saveWorkbook(imbalanced_workbook, file = binary_imbalanced_covariates_path, overwrite = TRUE)
  cat("\nFile Excel delle covariate binarie sbilanciate salvato in:", binary_imbalanced_covariates_path, "\n")
}

