source("project/config.R")

paths <- project_paths

training_set_path <- paths$training_set_path
dag_model_path <- paths$dag_model_path
dag_arcs_path <- paths$dag_arcs_path
dag_plot_svg_path <- paths$dag_plot_svg_path
dag_markov_blanket_svg_path <- paths$dag_markov_blanket_svg_path

required_packages <- c("bnlearn")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop(
    "Pacchetti mancanti: ",
    paste(missing_packages, collapse = ", "),
    ". Installali prima di eseguire questo script."
  )
}

if (!file.exists(training_set_path)) {
  stop("Training set non trovato in: ", training_set_path)
}

dir.create(dirname(dag_model_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(dag_arcs_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(dag_plot_svg_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(dag_markov_blanket_svg_path), recursive = TRUE, showWarnings = FALSE)

dag_data <- read.csv(training_set_path, stringsAsFactors = FALSE)
dag_data[] <- lapply(dag_data, factor)

dag_model <- bnlearn::hc(dag_data, score = "aic")
dag_score <- bnlearn::score(dag_model, data = dag_data, type = "aic")
dag_arcs <- bnlearn::arcs(dag_model)

saveRDS(dag_model, dag_model_path)
write.csv(dag_arcs, dag_arcs_path, row.names = FALSE)

compute_node_levels <- function(nodes, arcs) {
  node_levels <- stats::setNames(rep(1L, length(nodes)), nodes)

  if (nrow(arcs) == 0) {
    return(node_levels)
  }

  indegree <- stats::setNames(integer(length(nodes)), nodes)
  adjacency <- stats::setNames(vector("list", length(nodes)), nodes)

  for (i in seq_len(nrow(arcs))) {
    from_node <- arcs[i, "from"]
    to_node <- arcs[i, "to"]
    indegree[to_node] <- indegree[to_node] + 1L
    adjacency[[from_node]] <- c(adjacency[[from_node]], to_node)
  }

  processing_queue <- names(indegree[indegree == 0L])

  while (length(processing_queue) > 0) {
    current_node <- processing_queue[1]
    processing_queue <- processing_queue[-1]

    children <- adjacency[[current_node]]
    if (length(children) == 0) {
      next
    }

    for (child in children) {
      node_levels[child] <- max(node_levels[child], node_levels[current_node] + 1L)
      indegree[child] <- indegree[child] - 1L

      if (indegree[child] == 0L) {
        processing_queue <- c(processing_queue, child)
      }
    }
  }

  node_levels
}

compute_node_coordinates <- function(nodes, arcs) {
  node_levels <- compute_node_levels(nodes, arcs)
  layer_indices <- split(names(node_levels), node_levels)
  sorted_layers <- sort(as.integer(names(layer_indices)))

  incoming_map <- stats::setNames(vector("list", length(nodes)), nodes)
  outgoing_map <- stats::setNames(vector("list", length(nodes)), nodes)

  if (nrow(arcs) > 0) {
    for (i in seq_len(nrow(arcs))) {
      from_node <- arcs[i, "from"]
      to_node <- arcs[i, "to"]
      outgoing_map[[from_node]] <- c(outgoing_map[[from_node]], to_node)
      incoming_map[[to_node]] <- c(incoming_map[[to_node]], from_node)
    }
  }
  layer_membership <- layer_indices
  ordered_layer_keys <- as.character(sorted_layers)

  ordered_layers <- list()
  order_scores <- stats::setNames(rep(0, length(nodes)), nodes)

  for (layer_idx in seq_along(ordered_layer_keys)) {
    layer_name <- ordered_layer_keys[layer_idx]
    layer_nodes <- sort(layer_membership[[layer_name]])

    if (layer_idx == 1L) {
      order_scores[layer_nodes] <- seq_along(layer_nodes)
      ordered_layers[[layer_name]] <- layer_nodes
      next
    }

    parent_scores <- vapply(
      layer_nodes,
      function(node_name) {
        parent_nodes <- incoming_map[[node_name]]
        parent_nodes <- parent_nodes[parent_nodes %in% names(order_scores)]

        if (length(parent_nodes) == 0) {
          return(Inf)
        }

        mean(order_scores[parent_nodes])
      },
      numeric(1)
    )

    child_counts <- vapply(layer_nodes, function(node_name) length(outgoing_map[[node_name]]), integer(1))
    layer_nodes <- layer_nodes[order(parent_scores, -child_counts, layer_nodes)]
    order_scores[layer_nodes] <- seq_along(layer_nodes)
    ordered_layers[[layer_name]] <- layer_nodes
  }

  max_layer_size <- max(lengths(ordered_layers))
  layer_spacing_x <- if (length(ordered_layer_keys) <= 3) 2.8 else 2.35
  row_spacing_y <- if (max_layer_size <= 5) 2.2 else 1.7
  coordinates <- list()

  for (layer_idx in seq_along(ordered_layer_keys)) {
    layer_name <- ordered_layer_keys[layer_idx]
    layer_nodes <- ordered_layers[[layer_name]]
    layer_size <- length(layer_nodes)

    if (layer_size == 1L) {
      y_positions <- ((max_layer_size - 1) * row_spacing_y) / 2
    } else {
      y_positions <- seq(
        from = (max_layer_size - 1) * row_spacing_y,
        to = 0,
        length.out = layer_size
      )
    }

    x_position <- 1 + (layer_idx - 1) * layer_spacing_x

    for (i in seq_along(layer_nodes)) {
      coordinates[[layer_nodes[i]]] <- c(x = x_position, y = y_positions[i])
    }
  }

  list(
    coordinates = coordinates,
    max_x = 1 + (length(ordered_layer_keys) - 1) * layer_spacing_x,
    max_y = (max_layer_size - 1) * row_spacing_y
  )
}

draw_dag_plot <- function(nodes, arcs, main_title) {
  layout_info <- compute_node_coordinates(nodes, arcs)
  coordinates <- layout_info$coordinates
  x_padding <- 1.2
  y_padding <- 1.3
  node_width <- 0.72
  node_height <- 0.42

  format_node_label <- function(node_name) {
    pretty_name <- gsub("_categoriale$", "\n(categoriale)", node_name)
    pretty_name <- gsub("_binary$", "\n(binary)", pretty_name)
    pretty_name <- gsub("HeartDiseaseorAttack", "HeartDisease\norAttack", pretty_name, fixed = TRUE)
    pretty_name <- gsub("HvyAlcoholConsump", "HvyAlcohol\nConsump", pretty_name, fixed = TRUE)
    pretty_name <- gsub("AnyHealthcare", "Any\nHealthcare", pretty_name, fixed = TRUE)
    pretty_name <- gsub("NoDocbcCost", "NoDocbc\nCost", pretty_name, fixed = TRUE)
    pretty_name <- gsub("PhysActivity", "Phys\nActivity", pretty_name, fixed = TRUE)
    pretty_name <- gsub("Diabetes_binary", "Diabetes\nbinary", pretty_name, fixed = TRUE)
    pretty_name
  }

  plot(
    NA,
    xlim = c(1 - x_padding, layout_info$max_x + x_padding),
    ylim = c(-0.8, layout_info$max_y + y_padding),
    xaxt = "n",
    yaxt = "n",
    xlab = "",
    ylab = "",
    bty = "n",
    main = main_title
  )

  usr <- par("usr")
  rect(
    usr[1],
    usr[3],
    usr[2],
    usr[4],
    col = "#F7F3ED",
    border = NA
  )

  if (nrow(arcs) > 0) {
    for (i in seq_len(nrow(arcs))) {
      from_node <- arcs[i, "from"]
      to_node <- arcs[i, "to"]
      from_coord <- coordinates[[from_node]]
      to_coord <- coordinates[[to_node]]

      arrows(
        x0 = from_coord["x"] + node_width,
        y0 = from_coord["y"],
        x1 = to_coord["x"] - node_width,
        y1 = to_coord["y"],
        length = 0.075,
        lwd = 1.1,
        col = "#667085"
      )
    }
  }

  for (node_name in sort(nodes)) {
    coord <- coordinates[[node_name]]
    fill_color <- if (node_name == "Diabetes_binary") {
      "#D95F02"
    } else if (grepl("_categoriale$", node_name)) {
      "#A6CEE3"
    } else {
      "#FFF4CC"
    }

    rect(
      xleft = coord["x"] - node_width,
      ybottom = coord["y"] - node_height,
      xright = coord["x"] + node_width,
      ytop = coord["y"] + node_height,
      col = fill_color,
      border = "#3F3F46",
      lwd = 1.1
    )

    text(
      x = coord["x"],
      y = coord["y"],
      labels = format_node_label(node_name),
      cex = 0.66,
      font = if (node_name == "Diabetes_binary") 2 else 1
    )
  }

  legend(
    "bottomleft",
    inset = c(0.01, 0.01),
    legend = c("Variabile risposta", "Variabile discretizzata", "Altra covariata"),
    fill = c("#D95F02", "#A6CEE3", "#FFF4CC"),
    border = "#3F3F46",
    cex = 0.8
  )
}

save_dag_plot <- function(file_path, nodes_to_plot, arcs_to_plot, plot_title) {
  svg(filename = file_path, width = 16, height = 10.8, bg = "white")

  on.exit(dev.off(), add = TRUE)

  draw_dag_plot(
    nodes = nodes_to_plot,
    arcs = arcs_to_plot,
    main_title = plot_title
  )
}

all_nodes <- bnlearn::nodes(dag_model)
markov_blanket_nodes <- sort(c("Diabetes_binary", bnlearn::mb(dag_model, "Diabetes_binary")))
markov_blanket_arcs <- dag_arcs[
  dag_arcs[, "from"] %in% markov_blanket_nodes & dag_arcs[, "to"] %in% markov_blanket_nodes,
  ,
  drop = FALSE
]

save_dag_plot(
  dag_plot_svg_path,
  nodes_to_plot = all_nodes,
  arcs_to_plot = dag_arcs,
  plot_title = "DAG appreso con Hill Climbing e score AIC"
)
save_dag_plot(
  dag_markov_blanket_svg_path,
  nodes_to_plot = markov_blanket_nodes,
  arcs_to_plot = markov_blanket_arcs,
  plot_title = "Markov blanket di Diabetes_binary"
)

cat("Plot DAG vettoriale salvato in:", dag_plot_svg_path, "\n")
cat("Plot Markov blanket vettoriale salvato in:", dag_markov_blanket_svg_path, "\n")
cat("DAG salvato in:", dag_model_path, "\n")
cat("Archi del DAG salvati in:", dag_arcs_path, "\n")
cat("Score AIC del DAG:", dag_score, "\n")
cat("Numero di archi appresi:", nrow(dag_arcs), "\n")
