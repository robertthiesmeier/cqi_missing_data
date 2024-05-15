// Stata code and illustration of conditional quantile imputation (CQI)
// Manuscript: Multiple imputation for systematically missing effect modifiers in individual participant data meta-analysis
// Authors: Thiesmeier R, Hofer SM, Orsini N.


// Install CQI 
net describe "http://www.stats4life.se/stata/mi_impute_cqi"
net install mi_impute_cqi

// Check for mvmeta
quietly cap which mvmeta
if _rc != 0 qui scc install mvmeta 

// Load IPD data for postoperative radiotherapy on survival at different stages of the disease
use "http://fmwww.bc.edu/repec/bocode/i/ipdmetan_example.dta", clear

// recode variables to be consistent with description in the manuscript
recode stage (1=0) (2=1) (3=2), gen(z)
rename trt x 
rename tcens time
rename fail outcome 
gen zi1 = (z==1)
gen zi2 = (z==2)
gen x_zi1 = x*zi1 
gen x_zi2 = x*zi2 

// Analsysis with only complete studies  
preserve
keep if inlist(trialid, 1, 3, 10)!= 1
stset time, fail(outcome)

quietly mvmeta_make, by(trialid) clear names(b V): stcox x zi1 zi2 x_zi1 x_zi2 
mvmeta b V, fixed 

testparm bx_zi1 bx_zi2

* display results that are used for Table 3
lincom bx , eform cformat(%3.2f)
lincom bx + bx_zi1  , eform cformat(%3.2f)
lincom bx + bx_zi2 , eform cformat(%3.2f)
restore

* Including studies with systematic missing studies 
mi set wide
mi stset time, fail(outcome)
sts generate ch = na
gen x_ch = x*ch
gen x_d = x*_d 
mi register regular x ch _d x_ch x_d 
mi register imputed z
mi register passive zi1 zi2 x_zi1 x_zi2

* using CQI
mi impute cqi z x _t _d x_ch x_d sex age, add(30) id(trialid) rseed(150524)
	quietly mi passive: replace zi1 = (z==1)
	quietly mi passive: replace zi2 = (z==2)
	quietly mi passive: replace x_zi1 = x*zi1 
	quietly mi passive: replace x_zi2 = x*zi2 

quietly mvmeta_make, by(trialid) clear names(b V): mi estimate, post: stcox x zi1 zi2 x_zi1 x_zi2 
mvmeta b V, fixed 

* display results that are used for Table 3
testparm bx_zi1 bx_zi2
lincom bx , eform cformat(%3.2f)
lincom bx + bx_zi1  , eform cformat(%3.2f)
lincom bx + bx_zi2 , eform cformat(%3.2f)

exit
