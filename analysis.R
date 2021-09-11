
# AHS-2 Environmental Nutrition and Health

# Wiki page
browseURL("http://sph.wiki/keiji/projects:envnutr:start")

# Required packages
pacs <- c("tidyverse", "readxl", "tableone", "GGally", "egg", "DescTools")
sapply(pacs, require, character.only = TRUE)

# Read data ---------------------------------------------------------------

# Data file
zipfile <- list.files(path = "./data", pattern = "\\.zip$", full.names = TRUE)
fname <- unzip(zipfile, list=TRUE)$Name[2]
# fname <- list.files(path = "./data", pattern = "\\.csv$", full.names = TRUE)

# Read data -- 88,008 obs and 190 variables
# ev <- read_csv(fname[2]) %>% 
ev <- read_csv(unz(zipfile, fname)) %>% 
  arrange(analysisid) %>% 
  mutate(edu3cat = factor(edu3cat, levels = c("Highschool", "Some College", "College Degree")),
         female = factor(female, labels = c("Male", "Female")),
         black = factor(black, labels = c("Non-Black", "Black")))

# change variable names to lower casse
names(ev) <- tolower(names(ev))

# Make sure IDs are all unique
n_distinct(ev$analysisid)
ev %>% select(analysisid) %>% summary()

# Variables
names(ev)


# Demographics and lifestyle ----------------------------------------------

demo_vars <- c("agein", "bmi", "edu3cat", "female", "black")

# Note numbers of missing
ev %>% 
  select(all_of(demo_vars)) %>% 
  summary()

# Demographics table, unstratified
ev %>% 
  CreateTableOne(demo_vars, data = .) %>% 
  print(showAllLevels = TRUE)


# Define food groups and total variables ----------------------------------

total_vars <- c("kcal", "gram", "srv", "gw_kg", "lu_m2", "wc_m3")

# 28 Food groups
fg_name <- grep("_gram", names(ev), value = TRUE) %>% 
  gsub("_gram", "", .)

# Create lists of variables
kcal_vars <- paste0(fg_name, "_kcal")
gram_vars <- paste0(fg_name, "_gram")
srv_vars  <- paste0(fg_name, "_srv")
gwp_vars  <- paste0(fg_name, "_gw_kg")
lu_vars   <- paste0(fg_name, "_lu_m2")
wc_vars   <- paste0(fg_name, "_wc_m3")

# Winsorize food group variables at 99.9 percentitle
# Recalculate total kcal, gram, srv, gwp, lu, and wc
ev2 <- ev %>% 
  mutate(across(fruit_kcal:cereal_srv, Winsorize, probs = c(0, 0.999))) %>% 
  mutate(kcal = rowSums(across(all_of(kcal_vars))),
         gram = rowSums(across(all_of(gram_vars))),
         srv  = rowSums(across(all_of(srv_vars))),
         gw_kg = rowSums(across(all_of(gwp_vars))),
         lu_m2 = rowSums(across(all_of(lu_vars))),
         wc_m3 = rowSums(across(all_of(wc_vars))))

# Total intake and environmental impact -----------------------------------

ev2 %>% 
  select(all_of(total_vars)) %>% 
  summary()

# Distribution of total intake
# kcal restricted b/w 500 and 4500 kcal
ev2 %>% 
  select(kcal, gram, srv) %>% 
  psych::describe(quant=c(.25,.75)) %>% 
  rename(Q1 = Q0.25, Q3 = Q0.75) %>% 
  select(min, Q1, median, Q3, max, mean, sd, skew)

# Histogram of total intake in kcal, gram, servings per day
# pdf("./output/histogram total intake.pdf", width = 9, height = 3)
ev2 %>% 
  select(kcal, gram, srv) %>% 
  pivot_longer(kcal:srv, names_to = "variable", values_to = "value") %>% 
  mutate(variable = factor(variable, levels = total_vars[1:3])) %>% 
  ggplot(aes(x = value)) +
  geom_histogram(bins = 50) +
  facet_wrap(~ variable, scales = "free")
# dev.off()

ev2 %>% 
  select(kcal, gram, srv) %>% 
  ggpairs(lower = list(continuous = wrap("points", alpha = 0.2)))

# Compare kcal and gram intake
ev_highlight <- ev2 %>% filter(gram >= 9500)

# pdf("./output/scatterplot kcal vs gram.pdf", width = 7, height = 5)
ev2 %>% 
  ggplot(aes(x = gram, y = kcal)) + 
  geom_point(alpha = 0.2, shape = 16, stroke = 0) +
  geom_point(data = ev_highlight, aes(x = gram, y = kcal), shape = 1, size = 5, color = "red") +
  labs(x = "Total intake in gram/day", y = "Total intake in kcal/day")
# dev.off()

# Distribution of total env impact
ev2 %>% 
  select(gw_kg, lu_m2, wc_m3) %>% 
  # mutate_all(log) %>% 
  psych::describe(quant=c(.25,.75)) %>% 
  rename(Q1 = Q0.25, Q3 = Q0.75) %>% 
  select(min, Q1, median, Q3, max, mean, sd, skew)

# Histogram
# pdf("./output/histogram total env impact.pdf", width = 9, height = 3)
ev2 %>% 
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
ev2 %>% 
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

ev2 %>% all_desc(kcal_vars, digits = 1)
ev2 %>% all_desc(gram_vars, digits = 1)
ev2 %>% ll_desc(srv_vars, digits = 1)
ev2 %>% all_desc(gwp_vars)
ev2 %>% all_desc(lu_vars)
ev2 %>% all_desc(wc_vars)

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
ev2 %>% all_histogram(kcal_vars)
ev2 %>% all_histogram(gram_vars)
ev2 %>% all_histogram(srv_vars)
ev2 %>% all_histogram(gwp_vars)
ev2 %>% all_histogram(lu_vars)
ev2 %>% all_histogram(wc_vars)
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
  ev2 %>% MeanPlot(gwp_vars),
  ev2 %>% MeanPlot(lu_vars),
  ev2 %>% MeanPlot(wc_vars),
  ncol = 3
)
# dev.off()


# Kcal vs proportions of env impact from food groups ----------------------

pct_ev_plot <- function(vars, denominator, label){
  denominator <- sym(denominator)
  ylab <- paste("Food group", label, "/ Total", label, "* 100")
  tmp <- ev2 %>% 
    mutate_at(all_of(vars), ~ .x / !!denominator * 100) %>% 
    pivot_longer(all_of(vars[-28]), names_to = "Variable", values_to = "Value") %>% 
    mutate(Variable = factor(Variable, levels = vars[-28])) %>% 
    ggplot(aes(x = kcal, y = Value, color = Variable)) +
    geom_smooth() + 
    labs(x = "Total energy intake (kcal) per day", y = ylab)
  # tmp  + theme(legend.position = "bottom", legend.title = element_blank())
  tmp + facet_wrap(~Variable, ncol = 7) +
    theme(legend.position = "none")
}

pct_ev_plot(kcal_vars, "kcal", "Kcal")
pct_ev_plot(gwp_vars, "gw_kg", "GWP")
pct_ev_plot(lu_vars, "lu_m2", "LU")
pct_ev_plot(wc_vars, "wc_m3", "WC")
