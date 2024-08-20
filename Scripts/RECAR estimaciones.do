/*******************************************************************************
			   Evaluación RECAR (Registro de Exportadores de Carbón)
			  Ministerio de Desregulación y Transformación del Estado
					 Secretaria de Simplificación del Estado
								 Martín Rossi
					Autores: Abigail Riquelme y Facundo Gómez
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

*Importamos los datos mensuales:
import excel "$input/Exportaciones de Carbon vegetal stata", firstrow sheet("Datos Mensuales")

*===========================*
*		ESTIMACIONES
*===========================*

*Los datos que describen el Peso Neto (kg) y el Monto FOB en u$s se desagregan por categoría de producto, para las estimaciones se considera una única categoría general que agrupa todos los subproductos como Carbon Vegetal.
collapse (sum) PesoNetoKg MontoFOBenus, by(Fecha)
gen PesoNetoTn=PesoNetoKg/1000
gen MontoFOBenmilus=MontoFOBenus/1000

*Generamos la variable que define la tendencia en el tiempo del periodo analizado y aquella que define los meses tratados, que corresponden a todos aquellos que se encuentran después de la fecha que corresponde  al política (septiembre de 2012):
sort Fecha
gen t=_n
gen treat=0
replace treat=1 if Fecha>=mdy(9,1,2012)

*Agregamos un control más a la estimación que se define como la interacción entre la variable de tratamiento y la tendencia:
gen treat_t=treat*t

*A continuación se presentan las estimaciones, siguiendo un modelo de "Before and After" con tendencia temporal. En todos las especificaciones presentadas, tanto con frecuencia mensual o anual de los datos, el coeficiente asociado con "treat" es negativo y estadísticamente significativo para el peso. Al mismo tiempo, el coeficiente asociado con la interacción también resulta ser negativo y significativo, tanto para precio como para el monto. 
*Cabe agregar que, aunque la variable tratamiento para el precio reporta un coeficiente positivo, el efecto total de la intervención sobre el precio, dado por el coeficiente asociado al "treat" más el producto entre el coeficiente de "treat_t" por el valor de la tendencia para la observación tratada, resulta en valores negativos.

*** Variación Mensual ***
format _all %20.0g

reg PesoNetoTn treat t treat_t, robust
outreg2 using "$output/RECAR_tabla1.doc", ctitle("PesoNetoTn") dec(2) label replace

reg MontoFOBenmilus treat t treat_t, robust
outreg2 using "$output/RECAR_tabla1.doc", ctitle("MontoFOBenmilus") dec(2) label append

*Además, reportaremos los errores estándar consistentes con heterocedasticidad y autocorrelación de Newey y West (1994).
*El número óptimo de rezagos es el numero entero inferior de floor[4(258/100)^{2/9}]=4:

tsset t
unique t

newey PesoNetoTn treat t treat_t, lag(4)
outreg2 using "$output/RECAR_newey_tabla1.doc", ctitle("PesoNetoTn") dec(2) label nonotes replace 

newey MontoFOBenmilus treat t treat_t, lag(4)
outreg2 using "$output/RECAR_newey_tabla1.doc", ctitle("PesoNetoTn") dec(2) label nonotes append



