// Data Generating Mechanism to simulate one single study
capture program drop sim_one_study
program define sim_one_study, rclass
	syntax [anything] [ , nobs(real 500) filename(string) study(real 1) effect(string)]
	drop _all
		qui set obs `nobs'
		scalar follow_up = 10
		gen z = irecode(runiform(), .4, .8, 1)
		gen zi1 = (z==1)
		gen zi2 = (z==2)
		gen x = rbinomial(1, .5)
		gen x_zi1 = x*zi1 
		gen x_zi2 = x*zi2 
		scalar b0 = ln(10/1000)
		
		if "`effect'" == "" {
			di in red "Specify either common or random"
			exit 198
		}
		
		if "`effect'" == "common" {
			scalar b1 = ln(0.8)
			scalar b2 = ln(1.2) 
			scalar b3 = ln(1.5)  
			scalar b4 = ln(1)-ln(0.8)
			scalar b5 = ln(1.2)-ln(0.8)
		}
		
		else if "`effect'" == "random"{
			local tau = 0.05
			scalar b1 = rnormal(ln(0.8), `tau') 
			scalar b2 = rnormal(ln(1.2), `tau')  
			scalar b3 = rnormal(ln(1.5), `tau')  
			scalar b4 = rnormal(ln(1)-ln(0.8), `tau') 
			scalar b5 = rnormal(ln(1.2)-ln(0.8), `tau')
		}
		 
		scalar gamma = 1.4
		gen study = `study'
		gen time = (-ln(runiform())/exp(b0+b1*x+b2*zi1+b3*zi2+b4*(x_zi1)+b5*(x_zi2)))^(1/gamma)
		gen death = (time < follow_up)
		qui replace time = follow_up if time > follow_up
		qui stset time, fail(death)
		sts gen cumh = na
		gen x_cumh = cumh*x
		gen x_d = x*_d
	
	if "`filename'" != "" qui save "`filename'", replace 
end
