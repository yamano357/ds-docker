library(tidyverse)
library(remotes)

requirements_file <- commandArgs(trailingOnly = TRUE)[1]
cran_repos <- commandArgs(trailingOnly = TRUE)[2]
if (is.null(x = requirements_file)) {
  requirements_file <- "requirements.txt"
}
if (is.null(x = cran_repos)) {
  cran_repos <- "https://cran.ism.ac.jp/"
}

options(Ncpus = parallel::detectCores())
options(repos = c(CRAN = cran_repos))


parseRequirements <- function(...) {
  arg_list <- rlang::list2(...)
  if (all(arg_list[[2]]$src == "CRAN")) {
    arg_list[[1]] %>%
      tidyr::separate(
        data = .,
        col = "requirements", into = c("package", "type", "version"),
        sep = "[=<>]", remove = FALSE, fill = "right"
      ) %>%
      dplyr::filter(
        !is.element(el = .$package, set = tidyverse::tidyverse_packages())
      ) %>%
      dplyr::select(src, requirements, package, version) %>%
      return()
  } else if (all(arg_list[[2]]$src == "github")) {
    arg_list[[1]] %>%
      tidyr::separate(
        col = "requirements", into = c("package", "version"),
        sep = "@", remove = FALSE, fill = "right"
      ) %>%
      dplyr::mutate(
        package = stringr::str_remove(string = package, pattern = "^git.*?github.com/")
      ) %>%
      dplyr::filter(
        !is.element(el = .$package, set = tidyverse::tidyverse_packages())
      ) %>%
      tidyr::replace_na(list(version = "master")) %>%
      dplyr::select(src, requirements, package, version) %>%
      return()
  } else if (all(arg_list[[2]]$src == "Bioconductor")) {
    arg_list[[1]] %>%
      tidyr::separate(
        col = "requirements", into = c("version", "package"),
        sep = "/", remove = FALSE, fill = "left"
      ) %>%
      dplyr::mutate(
        version = stringr::str_remove(string = version, pattern = "^bioc::")
      ) %>%
      tidyr::separate(
        col = "package", into = c("package", "commit"),
        sep = "#", remove = FALSE, fill = "right"
      ) %>%
      dplyr::select(src, requirements, package, version) %>%
      return()
  }
}


installed_pkgs <- installed.packages() %>%
  tibble::as_tibble() %>%
  dplyr::select(package = Package, local_version = Version) %>%
  dplyr::distinct()
cran_pkgs <- remotes:::available_packages() %>%
  tibble::as_tibble() %>%
  dplyr::select(package = Package, cran_version = Version) %>%
  dplyr::distinct()

requirements_info <- readr::read_tsv(
  file = requirements_file,
  col_names = "requirements", col_types = list(requirements = readr::col_character()),
  comment = "#"
) %>%
  dplyr::mutate(
    src = dplyr::case_when(
      stringr::str_detect(
        string = .$requirements, pattern = "^git\\+git"
      ) ~ "github",
      stringr::str_detect(
        string = .$requirements, pattern = "^bioc::"
      ) ~ "Bioconductor",
      TRUE ~ "CRAN"
    )
  ) %>%
  dplyr::group_by(src) %>%
  dplyr::group_map(.f = parseRequirements, keep = TRUE) %>%
  dplyr::bind_rows() %>% 
  dplyr::left_join(y = installed_pkgs, by = c("package")) %>%
  dplyr::left_join(y = cran_pkgs, by = c("package")) %>%
  tidyr::replace_na(
    replace = list(version = "0.0.0", local_version = "0.0.0", cran_version = "0.0.0")
  )


if (nrow(x = requirements_info)) {
  # Bioconductor
  requirements_info %>%
    dplyr::filter(src == "Bioconductor") %>%
    dplyr::mutate(
      requirements = stringr::str_remove(string = requirements, pattern = "^bioc::")
    ) %>%
    dplyr::group_by(package) %>%
    purrr::walk(.x = .$requirements, .f = ~ remotes::install_bioc(repo = .x))

  # データソースがCRANでバージョン指定あり
  # 「指定バージョン」が「ローカルにあるパッケージのバージョン」よりも新しい場合はバージョンアップ
  requirements_info %>%
    dplyr::filter(src == "CRAN") %>%
    dplyr::filter(
      (version != "0.0.0") &
        (numeric_version(x = version) > numeric_version(x = local_version))
    ) %>%
    dplyr::group_by(package) %>%
    purrr::walk2(
      .x = .$package, .y = .$version,
      .f = ~ remotes::install_version(package = .x, version = .y)
    )

  # データソースがCRANでバージョン指定なし
  # 「CRANにあるバージョン」が「ローカルにあるバージョン」よりも新しい場合はまとめてバージョンアップ
  requirements_info %>%
    dplyr::filter(src == "CRAN") %>%
    dplyr::filter(
      (version == "0.0.0") &
        (
          is.na(x = local_version) |
            (numeric_version(x = cran_version) > numeric_version(x = local_version))
        )
    ) %>%
    dplyr::pull(var = package) %>%
    install.packages(pkgs = .)

  # GitHub
  requirements_info %>%
    dplyr::filter(src == "github") %>%
    dplyr::group_by(package) %>%
    purrr::walk2(
      .x = .$package, .y = .$version,
      .f = ~ remotes::install_github(repo = .x, ref = .y, upgrade = "always")
    )
}
