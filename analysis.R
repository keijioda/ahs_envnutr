
# AHS-2 Environmental Nutrition and Health

# Wiki page
browseURL("http://sph.wiki/keiji/projects:envnutr:start")

# Required packages
pacs <- c("tidyverse", "readxl", "tableone", "GGally", "egg", "DescTools")
sapply(pacs, require, character.only = TRUE)

# Read data ---------------------------------------------------------------

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
  rename(Q1 = Q0.25, Q3 = Q0.75) %>% 
  select(min, Q1, median, Q3, max, mean, sd, skew)

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
  # mutate_all(log) %>% 
  psych::describe(quant=c(.25,.75)) %>% 
  rename(Q1 = Q0.25, Q3 = Q0.75) %>% 
  select(min, Q1, median, Q3, max, mean, sd, skew)

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
    psych::describe(quant=c(.25,.75, .9, .95, .99, .995, .999)) %>% 
    select(min, Q0.25, median, Q0.75:Q0.999, max, mean, sd, skew) %>%
    print(digits = digits)
}

ev %>% all_desc(kcal_vars, digits = 1)
ev %>% all_desc(gram_vars, digits = 1)
ev %>% ll_desc(srv_vars, digits = 1)
ev %>% all_desc(gwp_vars)
ev %>% all_desc(lu_vars)
ev %>% all_desc(wc_vars)

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
  ev2 %>% 
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
    select(vars) %>% 
    summarize_all(mean) %>% 
    pivot_longer(vars, names_to = "Variable", values_to = "Mean") %>% 
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

ev_vars_std <- c("gw_kg_std", "lu_m2_std", "wc_m3_std")

ev %>% 
  pivot_longer(gw_kg_std:wc_m3_std, names_to = "variable", values_to = "value") %>% 
  mutate(variable = factor(variable, levels = ev_vars_std)) %>% 
  filter(!is.na(vegstat)) %>% 
  ggplot(aes(x = vegstat, y = value, fill = vegstat)) +
  geom_violin() +
  geom_boxplot(width = 0.1, fill = "white", outlier.shape = NA) +
  coord_flip() +
  scale_x_discrete(limits = rev(levels(ev$vegstat))) +
  scale_y_continuous(trans = scales::pseudo_log_trans(base = 10)) +
  facet_grid(~variable, scales = "free") +
  labs(x = "Dietary pattern") +
  theme(legend.position = "none")

ev %>% 
  pivot_longer(gw_kg_std:wc_m3_std, names_to = "variable", values_to = "value") %>% 
  mutate(variable = factor(variable, levels = ev_vars_std)) %>% 
  filter(!is.na(vegstat)) %>% 
  group_by(variable, vegstat) %>% 
  summarize(Median = median(value), Mean = mean(value), SD = sd(value))

  