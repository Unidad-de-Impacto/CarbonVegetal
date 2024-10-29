/*******************************************************************************
			   Evaluación RECAR (Registro de Exportadores de Carbón)
			  Ministerio de Desregulación y Transformación del Estado
					 Secretaria de Simplificación del Estado
********************************************************************************/
clear all
set more off

else if  "`c(username)'" == "Usuario" {
	global main "C:\Users\Usuario\Desktop\Trabajo - UdeSA\Trabajo - Ministerio\Evaluación RECAR"
}

*Crear carpetas de "input" (donde estará la base de datos) y "output" (para las tablas):
global input "$main/input"
global output "$main/output"

cd "$main"

*Guardamos como .dta la base de datos que contiene el Tipo de Cambio real Multilateral. Esta base de datos la usaremos posteriormente para hacer el merge de datos y usar el ITCRM como variable control.
import excel "$input/Exportaciones de Carbon vegetal stata", firstrow sheet("ITCRM")
save "$input\ITCRM.dta", replace

*Importamos los datos mensuales:
import excel "$input/Exportaciones de Carbon vegetal stata", firstrow sheet("Datos Mensuales") clear


*===========================*
*		ESTIMACIONES
*===========================*

*Los datos que describen el Peso Neto (Tn) y el Monto FOB en Millones de USD se desagregan por categoría de producto, para las estimaciones se considera una única categoría general que agrupa todos los subproductos como Carbon Vegetal.
collapse (sum) PesoNetoKg MontoFOBenus, by(Fecha)
gen PesoNetoTn=PesoNetoKg/1000
gen MontoFOBenmill=MontoFOBenus/1000000

*Generamos la variable que define la tendencia en el tiempo del periodo analizado y aquella que define los meses tratados, que corresponden a todos aquellos que se encuentran después de la fecha que corresponde a la política (septiembre de 2012):
sort Fecha
gen t=_n
gen treat=0
replace treat=1 if Fecha>=mdy(9,1,2012)

merge 1:1 Fecha using "$input\ITCRM.dta", nogen

*Agregamos un control más a la estimación que se define como la interacción entre la variable de tratamiento y la tendencia:
gen treat_t=treat*t

*A continuación se presentan las estimaciones, siguiendo un modelo de "Before and After" con tendencia temporal. En todas las especificaciones presentadas, el coeficiente asociado con "treat" es negativo y estadísticamente significativo para el peso. Al mismo tiempo, el coeficiente asociado con la interacción también resulta ser negativo y significativo, tanto para precio como para el monto. 
*Cabe agregar que, aunque la variable tratamiento para el monto reporta un coeficiente positivo, el efecto total de la intervención sobre el monto, dado por el coeficiente asociado al "treat" más el producto entre el coeficiente de "treat_t" por el valor de la tendencia para la observación tratada, resulta en valores negativos.

*** Variación Mensual ***
format _all %20.0g
label variable t "Tendencia"
label variable treat "Tratamiento"
label variable treat_ "Tratamiento*Tendencia"
label variable ITCRM "Tipo de Cambio Multilateral"

reg PesoNetoTn treat t treat_t ITCRM, robust
outreg2 using "$output/RECAR_tabla1.doc", nocons ctitle("Peso Neto (Tn)") dec(2) label nonotes addnote("Errores estandar entre parentesis", "*** p<0.01, ** p<0.05, * p<0.1", "El efecto promedio total de la politica sobre el monto FOB en el primer mes tratado es negativo, con un valor de -2.01") replace

reg MontoFOBenmill treat t treat_t ITCRM, robust
display (2.828161-.0413319*117) // El efecto total promedio de la política para el primer mes tratado ya arroja un valor negativo de -2.0076713. Como el efecto total de la intervención es decreciente a medida que pasa el tiempo, el efecto total pormedio sobre el monto FOB para todos los meses tratados será negativo.
outreg2 using "$output/RECAR_tabla1.doc", nocons ctitle("Monto FOB (Millones de USD)") dec(2) label nonotes addnote("Errores estandar entre parentesis", "*** p<0.01, ** p<0.05, * p<0.1", "El efecto promedio total de la politica sobre el monto FOB en el primer mes tratado es negativo, con un valor de -2.01") append 


*Además, reportaremos los errores estándar consistentes con heterocedasticidad y autocorrelación de Newey y West (1994).
*El número óptimo de rezagos es el numero entero inferior de floor[4(258/100)^{2/9}]=4:

tsset t
unique t

newey PesoNetoTn treat t treat_t ITCRM, lag(4)
outreg2 using "$output/RECAR_newey_tabla1.doc", nocons ctitle("Peso Neto (Tn)") dec(2) label nonotes addnote("Errores estandar consistentes con heterocedasticidad y autocorrelacion de Newey y West entre parentesis", "*** p<0.01, ** p<0.05, * p<0.1", "El efecto promedio total de la politica sobre el monto FOB en el primer mes tratado es negativo, con un valor de -2.01") replace 

newey MontoFOBenmill treat t treat_t ITCRM, lag(4)
outreg2 using "$output/RECAR_newey_tabla1.doc", nocons ctitle("Monto FOB (Millones de USD)") dec(2) label nonotes addnote("Errores estandar consistentes con heterocedasticidad y autocorrelacion de Newey y West entre parentesis", "*** p<0.01, ** p<0.05, * p<0.1", "El efecto promedio total de la politica sobre el monto FOB en el primer mes tratado es negativo, con un valor de -2.01") append



