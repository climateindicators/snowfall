# Build tidy long-format data for the Snowfall indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# Generated as a stub by the build-indicator skill. Each figure below has a
# `todo_reshape()` call standing where its reshape belongs. Replace that line,
# then delete the todo_reshape() helper once no call to it remains.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Snowfall",
  slug                    = "snowfall",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-snowfall/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-12/snowfall_td.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Change in Total Snowfall in the Contiguous 48 States, 1930-2007 ----

f1_path <- file.path(raw_dir, "snowfall_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f1_raw,
  id_cols          = c("Latitude", "Longitude"),
  expected_headers = "Trend",
  what             = "snowfall_fig-1.csv"
)

# One row per station, in EPA's order. Values stay character so the source
# digits survive byte for byte.
f1 <- transmute(f1_raw, latitude = Latitude, longitude = Longitude, value = Trend)

write_csv_stable(f1, file.path(out_dir, "snowfall_trend_by_station.csv"))

# ---- Figure 2: Change in Snow-to-Precipitation Ratio in the Contiguous 48 States, 1949-2024 ----

f2_path <- file.path(raw_dir, "snowfall_fig-2.csv")
f2_meta <- read_epa_preamble(f2_path)
f2_raw  <- read_epa_csv(f2_path)

# All columns are listed as expected headers so a rename or reorder stops the
# build from the first run. When you write the reshape, move the identifier
# columns into id_cols so the split between keys and series is explicit.
assert_headers(
  f2_raw,
  id_cols          = c("State", "Latitude", "Longitude"),
  expected_headers = c("Percent change (1949 - 2024)", "Significant (1 = sig, 0 = non-sig)"),
  what             = "snowfall_fig-2.csv"
)

# One row per station, in EPA's order. The Units: line's two "degrees" belong to
# the coordinate columns; the only measure is the percent change, so meta.yml
# carries that single unit. The significance flag qualifies the measure rather
# than being a second series, so it stays a column beside it. Values stay
# character so the source digits survive byte for byte.
f2 <- transmute(f2_raw, state = State, latitude = Latitude, longitude = Longitude,
                value = `Percent change (1949 - 2024)`,
                significant = `Significant (1 = sig, 0 = non-sig)`)

write_csv_stable(f2, file.path(out_dir, "snow_to_precip_ratio_change_by_station.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# One entry per output column, in order, filled from the data frame itself so it
# cannot drift. `type` and `description` are deliberately blank: tests/test-data.R
# fails while either is empty, so every column has to be documented by hand.
describe <- function(df, value) {
  docs <- list(
    state       = col("state", "string", "Two-letter postal code of the state the station is in"),
    latitude    = col("latitude", "number", "Latitude of the weather station, decimal degrees north"),
    longitude   = col("longitude", "number", "Longitude of the weather station, decimal degrees (negative = west)"),
    value       = col("value", "number", value),
    significant = col("significant", "integer", "1 if the trend is statistically significant, 0 if not")
  )
  unname(docs[names(df)])
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "snowfall_trend_by_station.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "snowfall_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "UTF-8",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = describe(f1,
                                 value = "Trend in total winter snowfall at the station, 1930-2007, percent change per year")
    ),
    list(
      file            = "snow_to_precip_ratio_change_by_station.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "snowfall_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "UTF-8",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = "percent change",
      rows            = nrow(f2),
      columns         = describe(f2,
                                 value = "Change in the snow-to-precipitation ratio at the station, 1949-2024, percent")
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
