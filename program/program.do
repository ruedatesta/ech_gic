clear all
set more off 


cap cd "/Users/horaciorueda/Documents/ech/"

set scheme s2color
global blue_cb "0 114 178"
global green_cb "0 158 115"
global red_cb " 213 94 0"

u ech2019
gen year=2019
rename HT11 ht11
rename HT13 ht13
rename pesoano w_ano

append using ech2023, force
replace year=2023 if year==.



gen ingreso_hogar=ht11-ht13
gen ingreso_per_capita=ingreso_hogar/ht19


gen ingreso_hogar_cte=.
	replace ingreso_hogar_cte=ingreso_hogar/75.62620*107.95 	if year==2019
	replace ingreso_hogar_cte=ingreso_hogar/103.31*107.95		if year==2023
	
gen ingreso_per_capita_cte=.
	replace ingreso_per_capita_cte=ingreso_per_capita/75.62620*107.95 	if year==2019
	replace ingreso_per_capita_cte=ingreso_per_capita/103.31*107.95		if year==2023	

* Quintiles por hogar
xtile qtile_hogar_19=ingreso_hogar_cte if year==2019 & nper==1 [w=w_ano], nq(5)
xtile qtile_hogar_23=ingreso_hogar_cte if year==2023 & nper==1 [w=w_ano], nq(5)


* Quintiles per capita
xtile qtile_per_capita_19=ingreso_per_capita_cte if year==2019 [w=w_ano], nq(5)
xtile qtile_per_capita_23=ingreso_per_capita_cte if year==2023 [w=w_ano], nq(5)


* Percentiles por hogar
xtile ptile_hogar_19=ingreso_hogar_cte if year==2019 & nper==1 [w=w_ano], nq(100)
xtile ptile_hogar_23=ingreso_hogar_cte if year==2023 & nper==1 [w=w_ano], nq(100)


* Percentiles per capita
xtile ptile_per_capita_19=ingreso_per_capita_cte if year==2019 [w=w_ano], nq(100)
xtile ptile_per_capita_23=ingreso_per_capita_cte if year==2023 [w=w_ano], nq(100)


* Matriz de ingresos a pesos corrientes - hogares (replica exante)
mat def A=J(3,5,.)

forvalues q=1/5 {
	local i=1
	foreach y in 19 23 {
		
		sum ingreso_hogar if year==20`y' & qtile_hogar_`y'==`q' & nper==1 [w=w_ano]
		mat A[`i',`q']=r(mean)
		local i=`i'+1
	}
	mat A[3,`q']=A[2,`q']/A[1,`q']-1
}


* Matriz de ingresos a pesos constantes - hogares y quintiles
mat def B=J(3,5,.)

forvalues q=1/5 {
	local i=1
	foreach y in 19 23 {
		
		sum ingreso_hogar_cte if year==20`y' & qtile_hogar_`y'==`q' & nper==1 [w=w_ano]
		mat B[`i',`q']=r(mean)
		local i=`i'+1
	}
	mat B[3,`q']=B[2,`q']/B[1,`q']-1
}

* Matriz de ingresos a pesos constantes - personas y quintiles
mat def C=J(3,5,.)

forvalues q=1/5 {
	local i=1
	foreach y in 19 23 {
		
		sum ingreso_per_capita_cte if year==20`y' & qtile_per_capita_`y'==`q' [w=w_ano]
		mat C[`i',`q']=r(mean)
		local i=`i'+1
	}
	mat C[3,`q']=C[2,`q']/C[1,`q']-1
}

* Matriz de ingresos a pesos constantes - hogares y percentiles
mat def D=J(3,100,.)

forvalues q=1/100 {
	local i=1
	foreach y in 19 23 {
		
		sum ingreso_hogar_cte if year==20`y' & ptile_hogar_`y'==`q' & nper==1 [w=w_ano]
		mat D[`i',`q']=r(mean)
		local i=`i'+1
	}
	mat D[3,`q']=D[2,`q']/D[1,`q']-1
}

* Matriz de ingresos a pesos constantes - personas y percentiles
mat def E=J(3,100,.)

forvalues q=1/100 {
	local i=1
	foreach y in 19 23 {
		
		sum ingreso_per_capita_cte if year==20`y' & ptile_per_capita_`y'==`q' [w=w_ano]
		mat E[`i',`q']=r(mean)
		local i=`i'+1
	}
	mat E[3,`q']=E[2,`q']/E[1,`q']-1
}

mat D=D'
mat E=E'

svmat E
svmat D

replace E3=E3*100
replace D3=D3*100
gen q=_n in 1/100

graph twoway connected D3 q, yscale(titlegap(*10)) xscale(titlegap(*10)) graphregion(color(white)) color("$blue_cb") ytitle("Crecimiento real (%)") xtitle("Centiles de ingreso - Hogares") yscale(r(-30(10)20)) ylabel(-30(10)20)
graph export "/Users/horaciorueda/Documents/ech/gic_2019_2023_h.png", as(png) width(2400) replace

graph twoway connected E3 q, yscale(titlegap(*10)) xscale(titlegap(*10)) graphregion(color(white)) color("$red_cb") ytitle("Crecimiento real (%)") xtitle("Centiles de ingreso - Personas") yscale(r(-30(10)20)) ylabel(-30(10)20)
graph export "/Users/horaciorueda/Documents/ech/gic_2019_2023_p.png", as(png) width(2400) replace




