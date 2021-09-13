# AHS-2 Environmental Nutrition

## Datasets

* File path: M:\Groups\Nutrition\Environmental Nutrition\AHS-2 Environment and Health
* File Name: baseline-environmental-data-per-subject-20210912.csv

* Includes n = 88,008 subjects and
* 190 variables:
  * `analysisid`
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
 [1] "cereal"     "snackfoods" "dessert"    "alcbev"     "cofftea"    "soda"       "water"     
 [8] "fish"       "pork"       "poultry"    "procmeat"   "beef"       "butter"     "margarine" 
[15] "dairysub"   "dairy"      "eggs"       "vegoil"     "sauce"      "nutseed"    "vegmeat"   
[22] "whlgrain"   "refgrain"   "legumes"    "potato"     "veg"        "fvjuice"    "fruit"  
```
## Demographics

```
                    level          Overall      
  n                                88008        
  agein (mean (SD))                58.32 (14.31)
  bmi (mean (SD))                  27.11 (5.84) 
  edu3cat (%)       Highschool     18627 (21.4) 
                    Some College   34350 (39.5) 
                    College Degree 33914 (39.0) 
  female (%)        Male           30921 (35.1) 
                    Female         57057 (64.9) 
  black (%)         Non-Black      65354 (74.7) 
                    Black          22175 (25.3) 
  vegstat (%)       Vegan           7351 ( 8.4) 
                    Lacto-ovo      26412 (30.0) 
                    Pesco           8655 ( 9.8) 
                    Semi            4772 ( 5.4) 
                    Non-veg        40817 (46.4) 
```
