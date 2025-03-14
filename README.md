# Imputation of discrete systematically missing variables

This repository includes the Stata code to illustrate the use of conditional quantile imputation (CQI) as described in the manuscript: "Multiple imputation for systematically missing effect modifiers in individual participant data meta-analysis" by Thiesmeier R, Hofer SM, Orsini N (2025). The Stata code uses the publicly available individual participant [data set](http://fmwww.bc.edu/repec/bocode/i/ipdmetan_example.dta), describing the effect of postoperative radiotherapy on survival at different stages of the disease. The CQI package described and used in the manuscript is available for Stata 18. A log-file of the example demonstrating the use of CQI is available [here](https://robertthiesmeier.github.io/cqi_missing_data/applied_example_cqi.html). In addition, the Data Generating Mechanism, as described in detail in the manuscript can be found in the [here](dgm.do).

## Download `mi impute cqi` :computer:
The Stata command can be downloaded from: 

```ruby

net describe "http://www.stats4life.se/stata/mi_impute_cqi"
net install mi_impute_cqi

```

## Example of postoperative radiotherapy on survival at different stages of the disease
In the paper, we describe the use of `mi impute cqi` to impute systematically missing effect modifiers. Below is an applied working example, illustrating the use of the command. We use the package `mvmeta` for the analysis (make sure it is installed).

```ruby

quietly cap which mvmeta
if _rc != 0 qui scc install mvmeta

```

Load IPD data for postoperative radiotherapy on survival at different stages of the disease. 

```ruby

use "http://fmwww.bc.edu/repec/bocode/i/ipdmetan_example.dta", clear

```

For simplicity, let us recode the variables in the orginal dataset to be consistent with the description in the manuscript.

```ruby

recode stage (1=0) (2=1) (3=2), gen(z)
rename trt x 
rename tcens time
rename fail outcome 
gen zi1 = (z==1)
gen zi2 = (z==2)
gen x_zi1 = x*zi1 
gen x_zi2 = x*zi2

```

The aim of the IPD meta-analysis is to estimate the effect of postoperative radiotherapy on survival at different stages of the disease. However, disease stage - the effect modifier - is systematically missing in three trials. A complete case analysis (only using the trials with data on disease stage) excludes trial 1, 3, and 10.

```ruby

preserve
keep if inlist(trialid, 1, 3, 10)!= 1
stset time, fail(outcome)

quietly mvmeta_make, by(trialid) clear names(b V): stcox x zi1 zi2 x_zi1 x_zi2 
mvmeta b V, fixed 

testparm bx_zi1 bx_zi2

lincom bx , eform cformat(%3.2f)
lincom bx + bx_zi1  , eform cformat(%3.2f)
lincom bx + bx_zi2 , eform cformat(%3.2f)
restore

```

How can we add the trials with 100% missing data on disease stage in our analysis? 
We can use a two-stage imputation process - `mi impute cqi` - to recover the missing values for disease stage in trial 1, 3, and 10.

```ruby

mi set wide
mi stset time, fail(outcome)
sts generate ch = na
gen x_ch = x*ch
gen x_d = x*_d 
mi register regular x ch _d x_ch x_d 
mi register imputed z
mi register passive zi1 zi2 x_zi1 x_zi2

mi impute cqi z x _t _d x_ch x_d sex age, add(30) id(trialid) rseed(150524)
	quietly mi passive: replace zi1 = (z==1)
	quietly mi passive: replace zi2 = (z==2)
	quietly mi passive: replace x_zi1 = x*zi1 
	quietly mi passive: replace x_zi2 = x*zi2

```

After we have imputed disease stage 30 times in the three trials, we can fit the substantive model in each imputed dataset and pool the estimates with Rubin's rules. We can use `mi estimate` to do that. 

```ruby

quietly mvmeta_make, by(trialid) clear names(b V): mi estimate, post: stcox x zi1 zi2 x_zi1 x_zi2 
mvmeta b V, fixed 

testparm bx_zi1 bx_zi2
lincom bx , eform cformat(%3.2f)
lincom bx + bx_zi1  , eform cformat(%3.2f)
lincom bx + bx_zi2 , eform cformat(%3.2f)

```

In this example, we have shown how to use `mi impute cqi` to impute systematically missing effect modifiers in an IPD meta-analysis of clinical trials. We can improve the generalisbility of the study findings and increase the precision of the point estimate by including an additonal three trials in the IPD meta-analysis. A more detailed account of the example can be found in the paper.
