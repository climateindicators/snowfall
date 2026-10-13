# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-snowfall/index.html>  \
  sha256 `df30c76c59d29a6346ecc9dbb4d6c4b88b9fdc8b38bed3b30436fa95d252d3fd`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-12/snowfall_td.pdf>

## Figure data

- `snowfall_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/sites/default/files/2016-08/snowfall_fig-1.csv>  \
  sha256 `b5a3c0b7eee39f1780c1d4bd1232d80a378d52ae0d1ebe84f5f8eaf77c825e9a`  \
  encoding UTF-8, 419 data rows, columns: `Latitude`, `Longitude`, `Trend`  \
  title: Figure 1. Change in Total Snowfall in the Contiguous 48 States, 1930-2007  \
  data source: Kunkel et al., 2009; web update: May 2014; units: percent change per year

- `snowfall_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-12/snowfall_fig-2.csv>  \
  sha256 `4ecfabfa797dce5d31baf61cf4962496df8c7621e0f465af9965a30a86084bec`  \
  encoding UTF-8, 170 data rows, columns: `State`, `Latitude`, `Longitude`, `Percent change (1949 - 2024)`, `Significant (1 = sig, 0 = non-sig)`  \
  title: Figure 2. Change in Snow-to-Precipitation Ratio in the Contiguous 48 States, 1949-2024  \
  data source: NOAA, 2024; web update: December 2024; units: degrees; degrees; percent change
