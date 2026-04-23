source("project/config.R")

paths <- project_paths

aic_selected_path <- paths$dag_markov_blanket_selected_vars_path
bic_selected_path <- paths$dag_bic_markov_blanket_selected_vars_path
training_set_path <- paths$training_set_path
output_xlsx_path <- paths$dag_variable_selection_comparison_xlsx_path

required_packages <- c("openxlsx")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop(
    "Pacchetti mancanti: ",
    paste(missing_packages, collapse = ", "),
    ". Installali prima di eseguire questo script."
  )
}

if (!file.exists(aic_selected_path)) {
  stop("File AIC non trovato in: ", aic_selected_path)
}

if (!file.exists(bic_selected_path)) {
  stop("File BIC non trovato in: ", bic_selected_path)
}

if (!file.exists(training_set_path)) {
  stop("Training set non trovato in: ", training_set_path)
}

dir.create(dirname(output_xlsx_path), recursive = TRUE, showWarnings = FALSE)

aic_selected <- read.csv(aic_selected_path, stringsAsFactors = FALSE)
bic_selected <- read.csv(bic_selected_path, stringsAsFactors = FALSE)
training_set <- read.csv(training_set_path, stringsAsFactors = FALSE)

aic_variables <- sort(unique(aic_selected$variable[aic_selected$variable != "Diabetes_binary"]))
bic_variables <- sort(unique(bic_selected$variable[bic_selected$variable != "Diabetes_binary"]))
all_variables <- sort(setdiff(names(training_set), "Diabetes_binary"))

comparison_table <- data.frame(
  Variabile = all_variables,
  AIC = ifelse(all_variables %in% aic_variables, "SI", "NO"),
  BIC = ifelse(all_variables %in% bic_variables, "SI", "NO"),
  stringsAsFactors = FALSE
)

priority_rank <- ifelse(
  comparison_table$AIC == "SI" & comparison_table$BIC == "SI",
  1L,
  ifelse(
    comparison_table$AIC == "SI" & comparison_table$BIC == "NO",
    2L,
    ifelse(
      comparison_table$AIC == "NO" & comparison_table$BIC == "SI",
      3L,
      4L
    )
  )
)

comparison_table <- comparison_table[order(priority_rank, comparison_table$Variabile), ]

workbook <- openxlsx::createWorkbook()
sheet_name <- "AIC_vs_BIC"
openxlsx::addWorksheet(workbook, sheet_name, gridLines = FALSE)

title_style <- openxlsx::createStyle(
  fontSize = 14,
  textDecoration = "bold",
  halign = "center"
)

header_style <- openxlsx::createStyle(
  textDecoration = "bold",
  fgFill = "#D9E2F3",
  border = "Bottom",
  halign = "center"
)

selected_style <- openxlsx::createStyle(
  fgFill = "#C6EFCE",
  fontColour = "#006100",
  halign = "center",
  border = "TopBottomLeftRight"
)

not_selected_style <- openxlsx::createStyle(
  fgFill = "#FDE9D9",
  fontColour = "#9C0006",
  halign = "center",
  border = "TopBottomLeftRight"
)

variable_style <- openxlsx::createStyle(
  halign = "left",
  border = "TopBottomLeftRight"
)

openxlsx::writeData(
  workbook,
  sheet = sheet_name,
  x = "Confronto selezione variabili: Markov blanket AIC vs BIC",
  startRow = 1,
  startCol = 1
)

openxlsx::mergeCells(workbook, sheet = sheet_name, cols = 1:3, rows = 1)
openxlsx::addStyle(workbook, sheet = sheet_name, style = title_style, rows = 1, cols = 1, gridExpand = TRUE)

openxlsx::writeData(workbook, sheet = sheet_name, x = comparison_table, startRow = 3, startCol = 1)
openxlsx::addStyle(workbook, sheet = sheet_name, style = header_style, rows = 3, cols = 1:3, gridExpand = TRUE)
openxlsx::addStyle(
  workbook,
  sheet = sheet_name,
  style = variable_style,
  rows = 4:(nrow(comparison_table) + 3),
  cols = 1,
  gridExpand = TRUE,
  stack = TRUE
)

for (col_idx in 2:3) {
  yes_rows <- which(comparison_table[[col_idx]] == "SI") + 3
  no_rows <- which(comparison_table[[col_idx]] == "NO") + 3

  if (length(yes_rows) > 0) {
    openxlsx::addStyle(
      workbook,
      sheet = sheet_name,
      style = selected_style,
      rows = yes_rows,
      cols = col_idx,
      gridExpand = TRUE,
      stack = TRUE
    )
  }

  if (length(no_rows) > 0) {
    openxlsx::addStyle(
      workbook,
      sheet = sheet_name,
      style = not_selected_style,
      rows = no_rows,
      cols = col_idx,
      gridExpand = TRUE,
      stack = TRUE
    )
  }
}

openxlsx::setColWidths(workbook, sheet = sheet_name, cols = 1, widths = 28)
openxlsx::setColWidths(workbook, sheet = sheet_name, cols = 2:3, widths = 12)
openxlsx::freezePane(workbook, sheet = sheet_name, firstActiveRow = 4)
openxlsx::saveWorkbook(workbook, output_xlsx_path, overwrite = TRUE)

cat("File Excel di confronto selezione variabili salvato in:", output_xlsx_path, "\n")
