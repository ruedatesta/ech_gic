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

recode region_4 (1=1) (2/4 = 0), gen(mdeo)
rename mes month

gen ipc=.
run "/Users/horaciorueda/Documents/GitHub/ech_gic/program/auxiliar_deflactor.do" // ipc 100=Oct 2022 (recordar que ine pregunta por ingreso del mes pasado)



gen ingreso_hogar=ht11-ht13 // Ingreso hogar sin valor locativo.
gen ingreso_hogar_per_capita=ingreso_hogar/ht19

gen ingreso_hogar_cte=ingreso_hogar/ipc
	
gen ingreso_hogar_per_capita_cte=.
	replace ingreso_hogar_per_capita_cte=ingreso_hogar_per_capita/ipc
	
* Quintiles por hogar (pare replicar gráfico de exante)
xtile qtile_hogar_19=ingreso_hogar_cte if year==2019 & nper==1 [w=w_ano], nq(5)
xtile qtile_hogar_23=ingreso_hogar_cte if year==2023 & nper==1 [w=w_ano], nq(5)

* Quintiles per capita
xtile qtile_per_capita_19=ingreso_hogar_per_capita_cte if year==2019 [w=w_ano], nq(5)
xtile qtile_per_capita_23=ingreso_hogar_per_capita_cte if year==2023 [w=w_ano], nq(5)

* Percentiles per capita
xtile ptile_per_capita_19=ingreso_hogar_per_capita_cte if year==2019 [w=w_ano], nq(100)
xtile ptile_per_capita_23=ingreso_hogar_per_capita_cte if year==2023 [w=w_ano], nq(100)


* Matriz de ingresos a pesos corrientes - hogares (replica exante)
mat def A=J(3,5,.)

forvalues q=1/5 {
	local i=1
	foreach y in 19 23 {
		
		sum ingreso_hogar_cte if year==20`y' & qtile_hogar_`y'==`q' & nper==1 [w=w_ano]
		mat A[`i',`q']=r(mean)
		local i=`i'+1
	}
	mat A[3,`q']=A[2,`q']/A[1,`q']-1
}


* Matriz de ingresos a pesos constantes - ingreso per capita del hogar y quintiles
mat def B=J(3,5,.)

forvalues q=1/5 {
	local i=1
	foreach y in 19 23 {
		
		sum ingreso_hogar_per_capita_cte if year==20`y' & qtile_per_capita_`y'==`q' [w=w_ano]
		mat B[`i',`q']=r(mean)
		local i=`i'+1
	}
	mat B[3,`q']=B[2,`q']/B[1,`q']-1
}



* Matriz de ingresos a pesos constantes - ingreso per capita del hogar y cenntiles
mat def C=J(3,100,.)

forvalues q=1/100 {
	local i=1
	foreach y in 19 23 {
		
		sum ingreso_hogar_per_capita_cte if year==20`y' & ptile_per_capita_`y'==`q' [w=w_ano]
		mat C[`i',`q']=r(mean)
		local i=`i'+1
	}
	mat C[3,`q']=C[2,`q']/C[1,`q']-1
}

mat B=B'
mat C=C'

svmat B
svmat C

replace B3=B3*100
replace C3=C3*100
gen q=_n in 1/5
gen c=_n in 1/100

graph twoway connected B3 q, yscale(titlegap(*10)) xscale(titlegap(*10)) graphregion(color(white)) color("$blue_cb") ytitle("Crecimiento real (%)") xtitle("Quintiles de ingreso per capita del hogar") yscale(r(-30(10)20)) ylabel(-30(10)20)
// graph export "/Users/horaciorueda/Documents/ech/gic_2019_2023_h.png", as(png) width(2400) replace

graph twoway connected C3 c, yscale(titlegap(*10)) xscale(titlegap(*10)) graphregion(color(white)) color("$red_cb") ytitle("Crecimiento real (%)") xtitle("Centiles de ingreso per capita del hogar") yscale(r(-30(10)20)) ylabel(-30(10)20)
graph export "/Users/horaciorueda/Documents/GitHub/ech_gic/figures/gic_2019_2023_c.png", as(png) width(2400) replace




