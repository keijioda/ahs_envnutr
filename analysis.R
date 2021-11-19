
# AHS-2 Environmental Nutrition and Health

# Github 
browseURL("https://github.com/keijioda/ahs_envnutr")

# Required packages
pacs <- c("tidyverse", "readxl", "tableone", "GGally", "egg", "DescTools")
sapply(pacs, require, character.only = TRUE)

# Read data ---------------------------------------------------------------

zipfile  <- "./data/baseline-environmental-data-per-subject-20210912.zip"
fname    <- "baseline-environmental-data-per-subject-20210912.csv"

source("dataprep.R")

# Demographics and lifestyle ----------------------------------------------

demo_vars

# Note numbers of missing
ev %>% 
  select(all_of(demo_vars)) %>% 
  summary()

# Demographics table, unstratified
ev %>% 
  CreateTableOne(demo_vars, data = .) %>% 
  print(showAllLevels = TRUE)


# Total intake and environmental impact -----------------------------------

ev %>% 
  select(all_of(total_vars)) %>% 
  summary()

# Distribution of total intake
# kcal restricted b/w 500 and 4500 kcal
ev %>% 
  select(kcal, gram, srv) %>% 
  psych::describe(quant=c(.25,.75)) %>% 
  as.data.frame() %>% 
  select(min, Q0.25, median, Q0.75, max, mean, sd, skew) %>% 
  mutate_all(round, 2)

# Histogram of total intake in kcal, gram, servings per day
# pdf("./output/histogram total intake.pdf", width = 9, height = 3)
ev %>% 
  select(kcal, gram, srv) %>% 
  pivot_longer(kcal:srv, names_to = "variable", values_to = "value") %>% 
  mutate(variable = factor(variable, levels = total_vars[1:3])) %>% 
  ggplot(aes(x = value)) +
  geom_histogram(bins = 50) +
  facet_wrap(~ variable, scales = "free")
# dev.off()

ev %>% 
  select(kcal, gram, srv) %>% 
  ggpairs(lower = list(continuous = wrap("points", alpha = 0.2)))

# Compare kcal and gram intake
ev_highlight <- ev %>% filter(gram >= 9500)

# pdf("./output/scatterplot kcal vs gram.pdf", width = 7, height = 5)
ev %>% 
  ggplot(aes(x = gram, y = kcal)) + 
  geom_point(alpha = 0.2, shape = 16, stroke = 0) +
  geom_point(data = ev_highlight, aes(x = gram, y = kcal), shape = 1, size = 5, color = "red") +
  labs(x = "Total intake in gram/day", y = "Total intake in kcal/day")
# dev.off()

# Distribution of total env impact
ev %>% 
  select(gw_kg, lu_m2, wc_m3) %>% 
  psych::describe(quant=c(.25,.75)) %>%
  as.data.frame() %>% 
  select(min, Q0.25, median, Q0.75, max, mean, sd, skew) %>% 
  mutate_all(round, 2)

# Histogram
# pdf("./output/histogram total env impact.pdf", width = 9, height = 3)
ev %>% 
  select(gw_kg, lu_m2, wc_m3) %>% 
  pivot_longer(gw_kg:wc_m3, names_to = "variable", values_to = "value") %>% 
  mutate(variable = factor(variable, levels = c("gw_kg", "lu_m2", "wc_m3"))) %>% 
  # mutate_if(is.numeric, log) %>% 
  ggplot(aes(x = value)) +
  geom_histogram(bins = 50) +
  facet_wrap(~ variable, scales = "free")
# dev.off()

# pdf("./output/scatterplot matrix total env impact.pdf", width = 6, height = 6)
# pdf("./output/scatterplot matrix log total env impact.pdf", width = 6, height = 6)
ev %>% 
  select(gw_kg, lu_m2, wc_m3) %>% 
  # mutate_all(log) %>%
  ggpairs(lower = list(continuous = wrap("points", alpha = 0.2, shape = 16, stroke = 0)))
# dev.off()


# Food group variables ----------------------------------------------------

fg_name

# Descriptive stats
all_desc <- function(data, vars, digits = 2){
  data %>% 
    select(all_of(vars)) %>% 
    psych::describe(quant=c(.25,.75)) %>%
    as.data.frame() %>% 
    select(min, Q0.25, median, Q0.75, max, mean, sd, skew) %>%
    mutate_all(round, digits)
}

ev %>% all_desc(kcal_vars, digits = 1)
ev %>% all_desc(gram_vars, digits = 1)
ev %>% all_desc(srv_vars)
ev %>% all_desc(gwp_vars, digits = 3)
ev %>% all_desc(lu_vars, digits = 3)
ev %>% all_desc(wc_vars, digits = 3)

# Histograms
all_histogram <- function(data, vars, ncol = 6, log = FALSE){
  out <- data %>% 
    select(all_of(vars)) %>% 
    pivot_longer(all_of(vars), names_to = "variable", values_to = "value") %>% 
    mutate(variable = factor(variable, levels = vars)) %>% 
    ggplot(aes(x = value)) +
    geom_histogram() +
    facet_wrap(~variable, scales = "free", ncol = ncol)
  
  if(log) out <- out + scale_x_continuous(trans = scales::pseudo_log_trans(base = 2))
  return(out)
}

# pdf("./output/histogram food groups.pdf", width = 11, height = 8)
ev %>% all_histogram(kcal_vars)
ev %>% all_histogram(gram_vars)
ev %>% all_histogram(srv_vars)
ev %>% all_histogram(gwp_vars)
ev %>% all_histogram(lu_vars)
ev %>% all_histogram(wc_vars)
# dev.off()

# Scatter plots between intake and env variable
compScatter <- function(fg, y, x = "_gram"){
  x_fg <- sym(paste0(fg, x))
  y_fg <- sym(paste0(fg, y))
  ev %>% 
    ggplot(aes(x = !!x_fg, y = !!y_fg)) + 
    geom_point(alpha = 0.2) + 
    geom_smooth(method = "lm", se = TRUE)
}

gwp_plots <- lapply(fg_name, compScatter, y = "_gw_kg")

# pdf("Scatterplot gram vs gwp.pdf", width = 11, height = 20)
ggarrange(plots = gwp_plots, ncol = 4)
# dev.off()

# Mean plots of environmental variables by food groups
MeanPlot <- function(data, vars){
  data %>% 
    select(all_of(vars)) %>% 
    summarize_all(mean) %>% 
    pivot_longer(all_of(vars), names_to = "Variable", values_to = "Mean") %>% 
    ggplot(aes(x = reorder(Variable, Mean), y = Mean)) + 
    geom_bar(stat = "identity") +
    coord_flip() +
    labs(x = "Food group")
}

# pdf("Mean plots env impact.pdf", width = 12, height = 4)
ggarrange(
  ev %>% MeanPlot(gwp_vars),
  ev %>% MeanPlot(lu_vars),
  ev %>% MeanPlot(wc_vars),
  ncol = 3
)
ggarrange(
  ev %>% MeanPlot(paste0(gwp_vars, "_std")),
  ev %>% MeanPlot(paste0(lu_vars, "_std")),
  ev %>% MeanPlot(paste0(wc_vars, "_std")),
  ncol = 3
)
# dev.off()

# Kcal vs proportions of env impact from food groups ----------------------

pct_ev_plot <- function(data, vars, denominator, label){
  denominator <- sym(denominator)
  ylab <- paste("Food group", label, "/ Total", label, "* 100")
  tmp <- data %>% 
    mutate_at(all_of(vars), ~ .x / !!denominator * 100) %>% 
    mutate(kcal = kcal / 1000) %>% 
    pivot_longer(all_of(vars), names_to = "Variable", values_to = "Value") %>% 
    mutate(Variable = factor(Variable, levels = vars)) %>% 
    ggplot(aes(x = kcal, y = Value, color = Variable)) +
    geom_smooth() + 
    labs(x = "Total energy intake per day (in 1000 kcal)", y = ylab)
  # tmp  + theme(legend.position = "bottom", legend.title = element_blank())
  tmp + facet_wrap(~Variable, ncol = 7) +
    theme(legend.position = "none")
}

ev %>% pct_ev_plot(kcal_vars, "kcal", "Kcal")
ev %>% pct_ev_plot(gwp_vars, "gw_kg", "GWP")
ev %>% pct_ev_plot(lu_vars, "lu_m2", "LU")
ev %>% pct_ev_plot(wc_vars, "wc_m3", "WC")

ev %>% pct_ev_plot(paste0(gwp_vars, "_std"), "gw_kg", "GWP")
ev %>% pct_ev_plot(paste0(lu_vars, "_std"), "lu_m2", "LU")
ev %>% pct_ev_plot(paste0(wc_vars, "_std"), "wc_m3", "WC")


# Compare distributions by dietary pattern --------------------------------

# Function to produce violin plots by dietary pattern
ev_by_vegstat_plot <- function(data, vars){
  data %>% 
    pivot_longer(all_of(vars), names_to = "variable", values_to = "value") %>% 
    mutate(variable = factor(variable, levels = vars)) %>% 
    filter(!is.na(vegstat)) %>% 
    ggplot(aes(x = vegstat, y = value, fill = vegstat)) +
    geom_violin() +
    geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA) +
    coord_flip() +
    scale_x_discrete(limits = rev(levels(ev$vegstat))) +
    scale_y_continuous(trans = scales::pseudo_log_trans(base = 10)) +
    facet_wrap(~variable) +
    labs(x = "Dietary pattern") +
    theme(legend.position = "none")
}

# Function to produce mean, SD and median by dietary pattern
ev_desc_stats_by_vegstat <- function(data, vars, digits = 3){
  data %>% 
    pivot_longer(all_of(vars), names_to = "variable", values_to = "value") %>% 
    mutate(variable = factor(variable, levels = vars)) %>% 
    filter(!is.na(vegstat)) %>% 
    group_by(variable, vegstat) %>% 
    summarize(Median = median(value), Mean = mean(value), SD = sd(value)) %>% 
    mutate_if(is.numeric, round, digits)
}

# Total environmental impact variables
ev_vars_std <- c("gw_kg_std", "lu_m2_std", "wc_m3_std")
ev %>% ev_by_vegstat_plot(ev_vars_std)

# Mean, SD and median by dietary pattern
ev %>% ev_desc_stats_by_vegstat(ev_vars_std)

# Kruskal-Wallis to compare across vegstat
ev[ev_vars_std] %>% 
  map_dfr(\(x) broom::tidy(kruskal.test(x ~ vegstat, data = ev))) %>% 
  mutate(Variable = ev_vars_std, p.value = Hmisc::format.pval(p.value)) %>% 
  select(Variable, method, statistic, p.value)

# By food groups... not very informative
ev %>% ev_by_vegstat_plot(gwp_vars_std)
ev %>% ev_by_vegstat_plot(lu_vars_std)
ev %>% ev_by_vegstat_plot(wc_vars_std)

# Mean plots of food groups by dietary pattern
mean_plot_by_vegstat <- function(data, vars){
  data %>% 
    ev_desc_stats_by_vegstat(vars) %>%
    mutate(vegstat = factor(vegstat, labels = c("V", "LO", "P", "S", "NV"))) %>% 
    ggplot(aes(x = vegstat, y = Mean, fill = vegstat)) +
    geom_bar(stat = "identity") +
    labs(x = "Dietary pattern") +
    facet_wrap(~variable, scales = "free") +
    theme(legend.position = "bottom")
}

ev %>% mean_plot_by_vegstat(gwp_vars_std)
ev %>% mean_plot_by_vegstat(lu_vars_std)
ev %>% mean_plot_by_vegstat(wc_vars_std)


# Correlation heat map ----------------------------------------------------

ev_heatmap <- function(data, vars, gsubstr, addrect){
  data %>% 
  select(all_of(vars)) %>% 
  rename_with(~gsub(gsubstr, "", .x)) %>% 
  cor(method = "spearman") %>% 
  corrplot::corrplot(method = "color", order = "hclust", hclust.method = "average", addrect = addrect, tl.col = "black", tl.cex = 0.8)
}

ev %>% ev_heatmap(gram_vars_std, "_gram_std", addrect = 3)
ev %>% ev_heatmap(gwp_vars_std, "_gw_kg_std", addrect = 3)
ev %>% ev_heatmap(lu_vars_std, "_lu_m2_std", addrect = 3)
ev %>% ev_heatmap(wc_vars_std, "_wc_m3_std", addrect = 3)

cormat <- ev %>% select(all_of(gram_vars_std)) %>% 
  rename_with(~gsub("_wc_m3_std", "", .x)) %>% 
  cor(method = "spearman")
cormat[abs(cormat) < .5] <- NA
cormat %>% print(na.print = "")


# Linear models: ev vs food group grams -----------------------------------

# Model setup
dv    <- "gw_kg_std"
covar <- c("kcal")
rhs <- paste(c(gram_vars_std, covar), collapse = " + ")
fm1 <- formula(paste(dv, "~", rhs))

# Change units before lm fit...
ev_lm <- ev %>% 
  mutate(kcal = kcal / 1000,
         gw_kg_std = gw_kg_std * 1000)

# Function to tidy beta estimates
extract_beta <- function(model){
  broom::tidy(model, conf.int = TRUE) %>% 
    slice(-1, -n()) %>% 
    select(term, estimate, conf.low, conf.high) %>%
    mutate(term = gsub("_gram_std", "", term)) %>% 
    arrange(-estimate) %>% 
    mutate(term = factor(term))
}

# Initial model
gw_mod1 <- lm(fm1, data = ev_lm) 
gw_mod1_coef <- extract_beta(gw_mod1) 

# log transformation?
gw_mod2 <- update(gw_mod1, log(.) ~ ., data = ev_lm) 
gw_mod2_coef <- extract_beta(gw_mod2) 

# Remove kcal from the model
gw_mod3 <- update(gw_mod1, . ~ . -kcal, data = ev_lm) 
gw_mod3_coef <- extract_beta(gw_mod3) 

# Remove pork from the model
gw_mod4 <- update(gw_mod1, . ~ . -pork_gram_std, data = ev_lm[ev_lm$pork_gram == 0,]) 
gw_mod4_coef <- extract_beta(gw_mod4) 

# Compare model fits between log(y) and untransformed
ggResidpanel::resid_compare(list(gw_mod1, gw_mod2), plots = c("resid", "qq"), smoother = TRUE)

# Diagnostics
par(mfrow = c(1, 2))
  plot(gw_mod1, which = 1:2)
par(mfrow = c(1, 1))

ggResidpanel::resid_panel(gw_mod1, plots = c("resid", "qq"))

# Plot beta estimates
gw_mod1_coef %>% 
  ggplot(aes(x = forcats::fct_reorder(term, estimate), y = estimate)) +
  geom_point() +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high)) + 
  coord_flip() +
  labs(x = "Intake of food groups (gram/day)",
       y = "Beta coefficients for GWP (with 95% CI)")

# Compare coefficient estimates
gw_mod1_coef %>% 
  mutate(model = "Include pork eaters") %>% 
  bind_rows(gw_mod4_coef %>% mutate(model = "Exclude pork eaters")) %>% 
  ggplot(aes(x = forcats::fct_reorder(term, estimate), y = estimate, color = model)) +
  geom_point() +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high)) + 
  coord_flip() +
  labs(x = "Intake of food groups (gram/day)",
       y = "Beta coefficients for GWP (with 95% CI)")

# GAMLSS ------------------------------------------------------------------

library(gamlss)

# Data for gamlss models
ev_gamlss <- ev %>% 
  dplyr::select(all_of(dv), all_of(covar), all_of(gram_vars_std)) %>% 
  mutate(kcal = kcal / 1000,
         gw_kg_std = gw_kg_std * 1000) %>% 
  na.omit()

# Normal error
gw_mod1 <- gamlss(fm1, family = NO, data = ev_gamlss) 
wp(gw_mod1, xlim.all = 5, ylim.all = 7)
title(paste("Normal: AIC = ", round(gw_mod1$aic)))
summary(gw_mod1)

# Generalized Gamma distribution (three parameters)
gw_mod2 <- gamlss(fm1, family = GG, data = ev_gamlss)
wp(gw_mod2, xlim.all = 5, ylim.all = 7)
title(paste("GG: AIC = ", round(gw_mod2$aic)))

# Generalized beta of the second kind (four parameters)
gw_mod3 <- gamlss(fm1, family = GB2, method = mixed(5, 30), data = ev_gamlss)
wp(gw_mod3, xlim.all = 5, ylim.all = 2)
title(paste("GB2: AIC = ", round(gw_mod3$aic)))

# Adding model for variance
sfm1 <- formula(paste("~", rhs))
gw_mod4 <- gamlss(fm1, sigma.fo = sfm1, nu.fo = sfm1, family = GB2, method = mixed(5, 100), data = ev_gamlss)
wp(gw_mod4, xlim.all = 5, ylim.all = 2)
title(paste("GB2: AIC = ", round(gw_mod4$aic)))
GAIC(gw_mod4)

summary(gw_mod4)
