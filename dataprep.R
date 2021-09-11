
# AHS-2 Environmental Nutrition and Health
# Data preparation

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
if (n_distinct(ev$analysisid) != nrow(ev)) {
  warnings("IDs are not unique")
} else{
  message("All IDs are unique!")
}

# Demographics and lifestyle ----------------------------------------------

demo_vars <- c("agein", "bmi", "edu3cat", "female", "black")

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
ev <- ev %>% 
  mutate(across(fruit_kcal:cereal_srv, Winsorize, probs = c(0, 0.999))) %>% 
  mutate(kcal = rowSums(across(all_of(kcal_vars))),
         gram = rowSums(across(all_of(gram_vars))),
         srv  = rowSums(across(all_of(srv_vars))),
         gw_kg = rowSums(across(all_of(gwp_vars))),
         lu_m2 = rowSums(across(all_of(lu_vars))),
         wc_m3 = rowSums(across(all_of(wc_vars))))
