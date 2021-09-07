
# AHS-2 Environmental Nutrition and Health

# Wiki page
browseURL("http://sph.wiki/keiji/projects:envnutr:start")

# Required packages
pacs <- c("tidyverse", "readxl", "tableone")
sapply(pacs, require, character.only = TRUE)

# Read data ---------------------------------------------------------------

# Data file
zipfile <- list.files(path = "./data", pattern = "\\.zip$", full.names = TRUE)
fname <- unzip(zipfile, list=TRUE)$Name[2]

# Read data -- 88,008 obs and 190 variables
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


# Total intake and environmentas impact -----------------------------------

total_vars <- c("kcal", "gram", "srv", "gw_kg", "lu_m2", "wc_m3")

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
# pdf("histogram total intake.pdf", width = 9, height = 3)
ev %>% 
  select(kcal, gram, srv) %>% 
  pivot_longer(kcal:srv, names_to = "variable", values_to = "value") %>% 
  mutate(variable = factor(variable, levels = total_vars[1:3])) %>% 
  ggplot(aes(x = value)) +
  geom_histogram(bins = 50) +
  facet_wrap(~ variable, scales = "free")
# dev.off()

