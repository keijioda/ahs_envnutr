# AHS-2 Environmental Nutrition

## Datasets

* File path: M:\Groups\Nutrition\Environmental Nutrition\AHS-2 Environment and Health
* File Name: baseline-environmental-data-per-subject-20210824.csv

* Includes n = 88,008 subjects and
* 187 variables:
  * Demographics:
    * Age at baseline: `agein`
    * BMI: `bmi`
    * Education, 3 levels: `edu3cat`
    * Gender: `female`
    * Race (Black/Non-Black): `black`
  * Total intake in kcal, gram and servings per day
  * 28 food groups in:
    * kcal/day: `*_kcal`
    * gram/day: `*_gram`
    * standard servings/day: `*_srv`
    * GWP (kg CO2-eq): `*_gw_kg`
    * land use (m²a): `*_lu_m2`
    * water consumption (m³): `*_wc_m3`
    * (replace * with food group name – see below)

* There are 28 food groups:
```
 [1] "fruit"      "fvjuice"    "veg"        "potato"     "legumes"    "refgrain"   "whlgrain"  
 [8] "vegmeat"    "nutseed"    "sauce"      "vegoil"     "eggs"       "dairy"      "dairysub"  
[15] "margarine"  "butter"     "beef"       "procmeat"   "poultry"    "pork"       "fish"      
[22] "water"      "soda"       "cofftea"    "alcbev"     "dessert"    "snackfoods" "cereal"  
```
