# Regression checks on the generated data for the Snowfall indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 2 dataset(s)", length(meta$datasets) == 2L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
# Pinned from snowfall_fig-1.csv (Kunkel et al., 2009; web update May 2014).
# A legitimate data update fails here and says exactly what changed.
row_str <- function(df, i) paste(unlist(df[i, ]), collapse = "|")
extreme <- function(df, fn) row_str(df, fn(as.numeric(df$value)))

f1 <- rd("snowfall_trend_by_station.csv")
check("snowfall trend: 419 stations", nrow(f1) == 419L)
check("snowfall trend: first row", row_str(f1, 1) == "34.52|-109.38|-1.691")
check("snowfall trend: last row", row_str(f1, 419) == "42.08|-104.22|0.052")
check("snowfall trend: min is -3.057", extreme(f1, which.min) == "46.97|-123.82|-3.057")
check("snowfall trend: max is 1.92", extreme(f1, which.max) == "36.75|-105.6|1.92")
check("snowfall trend: every value is numeric", !anyNA(suppressWarnings(as.numeric(f1$value))))

# Pinned from snowfall_fig-2.csv (NOAA, 2024; web update December 2024).
f2 <- rd("snow_to_precip_ratio_change_by_station.csv")
check("snow/precip ratio: 170 stations", nrow(f2) == 170L)
check("snow/precip ratio: first row", row_str(f2, 1) == "CA|39.1678|-120.1428|1.02|0")
check("snow/precip ratio: last row", row_str(f2, 170) == "NY|40.7789|-73.9692|-3.0975|0")
check("snow/precip ratio: min is -42.2475 (KS)",
      extreme(f2, which.min) == "KS|39.7675|-101.8067|-42.2475|1")
check("snow/precip ratio: max is 15.99 (UT)",
      extreme(f2, which.max) == "UT|41.525|-111.1494|15.99|1")
check("snow/precip ratio: 69 significant, 101 not",
      identical(as.integer(table(factor(f2$significant, c("0", "1")))), c(101L, 69L)))
check("snow/precip ratio: 31 states", length(unique(f2$state)) == 31L)
check("snow/precip ratio: every value is numeric", !anyNA(suppressWarnings(as.numeric(f2$value))))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
