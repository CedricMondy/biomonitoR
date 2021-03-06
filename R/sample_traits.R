#' @describeIn assign_traits sample_traits

sample_traits <- function(x) {
  unique.tx <- unique(x[, "Taxa"])
  res <- lapply(unique.tx, function(y) (x[sample(rownames(x[x$Taxa == y, ]), 1), ]))
  res <- do.call(rbind, res)
  rownames(res) <- NULL
  res[, -c(2:5)]
}
