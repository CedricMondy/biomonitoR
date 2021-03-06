test_that("traits", {
  load(system.file("testdata", "macro_traits.rda", package="biomonitoR"))
  load(system.file("testdata", "traits.rda", package="biomonitoR"))
  load(system.file("testdata", "assigned_traits.rda", package="biomonitoR"))

  data_bio <- as_biomonitor(macro_traits, FUN = bin)
  data_agr <- aggregate_taxa(data_bio)
  data_at <- assign_traits(data_agr, trait_db = traits)
  data_at_f <- assign_traits(data_agr, trait_db = traits, filter_by_distance = 0)
  expect_equal(assigned_traits, data_at)
  expect_equal(assigned_traits[assigned_traits$Taxonomic_distance == 0, ], data_at_f)
  expect_equal(assign_traits(data_agr, trait_db = traits, filter_by_distance = "pos"), data_at[data_at[, "Taxonomic_distance"] >= 0, ] )
  expect_equal(assign_traits(data_agr, trait_db = traits, filter_by_distance = "neg"), data_at[data_at[, "Taxonomic_distance"] <= 0, ] )
  expect_error(assign_traits(data_agr, trait_db = traits, filter_by_distance = "eig"), "pos, neg or an integer are needed when filter_by_distance is not NULL" )

  # macrophytes
  # importing data in the biomonitoR format
  oglio_asb <- as_biomonitor(oglio, group = "mf", FUN = bin)
  oglio_agg <- aggregate_taxa(oglio_asb)
  oglio_agg_cust <- oglio_agg
  class(oglio_agg_cust) <- c("biomonitoR", "custom")

  expect_warning(assign_traits(oglio_agg_cust, group = "mf"), "It seems that you used your own reference database. Please check the consistency of the taxonomy used for calculating the index with those of your reference database to have reliable results.")
  expect_error(assign_traits(oglio_agg , trait_db = traits_mf , group = "mf", tax_lev = "Order"), "Maximum taxonomic level is family.")

  # no need to run assign_traits, just to show its use
  oglio_ts <- assign_traits(oglio_agg , trait_db = traits_mf , group = "mf")
  oglio_ts_fam <- assign_traits(oglio_agg , trait_db = traits_mf , group = "mf", tax_lev = "Family")
  expect_equal(dim(oglio_ts), c(40, 28))



})


test_that("sample_traits", {
  data(macro_ex)
  data_bio <- as_biomonitor(macro_ex)
  data_agr <- aggregate_taxa(data_bio)
  data_ts <- assign_traits(data_agr)

  load(system.file("testdata", "sample_traits_run1.rda", package="biomonitoR"))
  load(system.file("testdata", "sample_traits_run2.rda", package="biomonitoR"))

  set.seed(2021)
  expect_equal(sample_traits(data_ts)[, 1, drop = FALSE], sample_traits_run1[, 1, drop = FALSE])
  expect_equal(sample_traits(data_ts)[, 1, drop = FALSE], sample_traits_run2[, 1, drop = FALSE])
})


test_that("fd_indices", {
  data(macro_ex)
  data_bio <- as_biomonitor(macro_ex)
  data_agr <- aggregate_taxa(data_bio)
  data_ts <- assign_traits(data_agr)
  data_ts_av <-average_traits(data_ts)
  data_ts_av_m <- data_ts_av
  col_blocks <- c(8, 7, 3, 9, 4, 3, 6, 2, 5, 3, 9, 8, 8, 5, 7, 5, 4, 4, 2, 3, 8)

  rownames(data_ts_av_m) <- data_ts_av$Taxa
  traits_prep <- ade4::prep.fuzzy(data_ts_av_m[, -1], col.blocks = col_blocks)

  traits_dist <- ade4::ktab.list.df(list(traits_prep))
  traits_dist <- ade4::dist.ktab(traits_dist, type = "F")
  traits_dist_m <- as.matrix(traits_dist)

  taxa_comm <- convert_to_vegan(data_agr, tax_lev = "Taxa")
  taxa_comm <- taxa_comm[, colnames(taxa_comm) %in% rownames(traits_dist_m)]
  traits_dist_m <- traits_dist_m[rownames(traits_dist_m) %in% colnames(taxa_comm), colnames(traits_dist_m) %in% colnames(taxa_comm)]
  trait_dist <- as.dist(traits_dist_m)

  fd_res <- FD::dbFD(trait_dist, taxa_comm, message = FALSE, stand.FRic = FALSE, scale.RaoQ = FALSE, corr = "none")
  check_pcoa_nbdim <- select_pcoa_axes(trait_dist, tresh = 0.91)
  check_pcoa_nbdim_3 <- select_pcoa_axes(trait_dist, tresh = 0.39)

  fd_res_3 <- FD::dbFD(trait_dist, taxa_comm, message = FALSE, stand.FRic = TRUE, scale.RaoQ = TRUE, corr = "none", m = 3)
  f_rich_ex3 <- f_rich(data_agr, trait_db = traits_dist, nbdim = 3)
  f_divs_ex3 <- f_divs(data_agr, trait_db = traits_dist)
  f_red <- f_divs(data_agr, trait_db = traits_dist)
  f_rich_ex3_df <- f_rich(data_agr, trait_db = data_ts_av, type = "F", nbdim = 3, col_blocks = col_blocks)
  f_rich_ex3_df_tb <- f_rich(data_agr, trait_db = data_ts_av, type = "F", nbdim = 3, col_blocks = col_blocks, traceB = TRUE)
  f_eve_ex3 <- f_eve(data_agr, trait_db = traits_dist, nbdim = 33)
  f_red_ex3 <- f_red(data_agr, trait_db = traits_dist)
  f_red_ex3_rao <- f_red_ex3[, 2]
  names(f_red_ex3_rao) <- rownames(f_red_ex3)

  # FD uses all the PCoA dimensions
  fdisp_2 <- FD::fdisp(trait_dist, as.matrix(taxa_comm))[[1]]
  f_disp_ex2 <- f_disp(data_agr, trait_db = traits_dist, nbdim = 33)

  expect_equal(f_rich_ex3, fd_res_3$FRic)
  expect_equal(f_rich_ex3_df, fd_res_3$FRic)
  expect_equal(f_divs_ex3, fd_res_3$RaoQ)
  expect_equal(check_pcoa_nbdim$r2, fd_res$qual.FRic)
  expect_equal(check_pcoa_nbdim_3$r2, fd_res_3$qual.FRic)
  expect_equal(length(f_rich_ex3_df_tb), 7)
  expect_equal(f_red_ex3_rao, fd_res_3$RaoQ)
  expect_equal(f_disp_ex2, fdisp_2)
  expect_equal(f_eve_ex3, fd_res_3$FEve)
})

