
# AHS-2 Environmental Nutrition and Health
# Data preparation

# Read data ---------------------------------------------------------------

# Data file
# If local, unzip a zip file and read a csv 
# If rstudio cloud, read a csv file directly

if (file.exists(zipfile)){
  ev <- read_csv(unz(zipfile, fname))
} else {
  fname <- paste0("./data/", fname)
  ev <- read_csv(fname)
}

# Read data -- 88,008 obs and 190 variables
ev <- ev %>% 
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

demo_vars <- c("agein", "bmi", "edu3cat", "female", "black", "vegstat")

# Define dietary pattern --------------------------------------------------

# Need to change the default order of vegstat...
dp_lab <- c("Vegan", "Lacto-ovo", "Semi", "Pesco", "Non-veg")
dp_lev <- c("Vegan", "Lacto-ovo", "Pesco", "Semi", "Non-veg")
ahs <- read_csv("./data/ahs_vegstat.csv")
ev <- ev %>% 
  left_join(ahs, by = "analysisid") %>%
  mutate(vegstat = factor(vegstat, labels = dp_lab)) %>% 
  mutate(vegstat = factor(vegstat, levels = dp_lev))
message("Read AHS vegstat data and left-joined...")

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
  mutate(across(cereal_kcal:fruit_srv, Winsorize, probs = c(0, 0.999))) %>% 
  mutate(kcal  = rowSums(across(all_of(kcal_vars))),
         gram  = rowSums(across(all_of(gram_vars))),
         srv   = rowSums(across(all_of(srv_vars))),
         gw_kg = rowSums(across(all_of(gwp_vars))),
         lu_m2 = rowSums(across(all_of(lu_vars))),
         wc_m3 = rowSums(across(all_of(wc_vars))))
message("Data winsorized...")

# Standardize env vars to 2000 kcal ---------------------------------------

# Function for energy-standardization with zero partition
kcal_standardize <- function(var, kcal, value = 2000, log = TRUE){
  df <- data.frame(y = var, ea_y = var, kcal = kcal)
  count_negative <- sum(df$y < 0, na.rm=TRUE)
  if (count_negative > 0)
    warning("There are negative values in variable.")
  if(log) df$y[df$y > 0 & !is.na(df$y)] <- log(df$y[df$y > 0 & !is.na(df$y)])
  mod <- lm(y ~ kcal, data=df[df$y != 0, ])
  pred_y <- predict(mod, data.frame(kcal = 2000))
  if(log){
    ea <- exp(resid(mod) + pred_y)
    df$ea_y[!is.na(df$y) & df$y != 0] <- ea
  }
  else{
    ea <- resid(mod) + pred_y
    df$ea_y[!is.na(df$y) & df$y != 0] <- ea
  }
  return(df$ea_y)
}

# Create new variables
gwp_vars_std <- paste0(gwp_vars, "_std")
lu_vars_std  <- paste0(lu_vars,  "_std")
wc_vars_std  <- paste0(wc_vars,  "_std")

# and standardize
ev[gwp_vars_std] <- lapply(ev[gwp_vars], kcal_standardize, kcal = ev$kcal)
ev[lu_vars_std]  <- lapply(ev[lu_vars],  kcal_standardize, kcal = ev$kcal)
ev[wc_vars_std]  <- lapply(ev[wc_vars],  kcal_standardize, kcal = ev$kcal)

# Sum up standardized values
ev <- ev %>% 
  mutate(gw_kg_std = rowSums(across(all_of(gwp_vars_std))),
         lu_m2_std = rowSums(across(all_of(lu_vars_std))),
         wc_m3_std = rowSums(across(all_of(wc_vars_std))))

message("Standardized variables created...")
