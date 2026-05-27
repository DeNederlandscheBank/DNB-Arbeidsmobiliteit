
************************************************************
*** 1_gba.do        				       	 ***
*** Read source data about population admin (GBA)	 ***
*** Author: Cindy Biesenbeek (DNB)			 *** 	
*** January 2026		                         ***
************************************************************

************************************************************
/*
NOTES

Explanation: This do-file reads in basic population data like gender, age, etc. Note that every one ever registered in public population files are included, including people that passed away or migrated. 
*/
************************************************************

*** Settings
set more off
set dp comma
capture log close
log using "H:\logs\1_gba.smcl", replace

*** locals for source data 
	local gba 			"G:\Bevolking\GBAPERSOONTAB\2024\GBAPERSOON2024TABV3.dta" 
	local landencodes 		"H:\tussen\LANDAKTUEELREFV13.dta"		// this version is not available in K-directory yet, converted manually
*	local vars			"RINPERSOONS RINPERSOON GBAGESLACHT GBAHERKOMSTGROEPERING GBAGENERATIE GBAGEBOORTEJAAR GBAGEBOORTEMAAND GBAGEBOORTEDAG GBAGESLACHT"
	local vars 			"rinpersoons rinpersoon gbageslacht gbaherkomstgroepering gbageneratie gbageboortejaar gbageboortemaand gbageboortedag"

	
************************
************************
*** 1. Read gba data ***
************************
************************

	use `vars' using "`gba'" if rinpersoons=="R", clear
	ren *, lower

*** Check duplicates
	duplicates tag, gen(dubbel)
	assert dubbel==0
	drop dubbel

	
*************************************
*************************************
*** 2. Create basic pop variables ***
*************************************
*************************************	
	
*** Date of birth
	destring gbageboorte*, replace
	gen geboortedatum = mdy(gbageboortemaand,gbageboortedag,gbageboortejaar)
	label var geboortedatum "Geboortedatum"	
	format geboortedatum %td
	drop gbageboorte*

	
*** Gender
	destring gbageslacht, gen(geslacht)
	label def geslacht 1 "Man" 2 "Vrouw"
	label val geslacht geslacht
	label var geslacht "Geslacht"

	
*** Migration background

	*** create temporary file to merge country codes
		compress
		save "H:\tussen\gba_tijdelijk.dta", replace

	*** read file country codes
		use "`landencodes'", clear
		rename *, lower
		rename land gbaherkomstgroepering
 
	*** non-western groups of orgin
		destring etngrp, replace
		label def etngrp 0	"Autochtoon" 1	"Marokko" 2	"Turkije" 3	"Suriname" 4 "Voormalige Nederlandse Antillen en Aruba" 5 "Overige niet-westerse landen" 6 "Overige westerse landen" 7 "Onbekend"
		label val etngrp etngrp 

		gen herkomst = .
			replace herkomst = 1 if etngrp==0
			replace herkomst = 2 if etngrp==6
			replace herkomst = 3 if inrange(etngrp,1,4)|etngrp==5
		label def herkomst 1 "Nederlands" 2 "Westers" 3 "Niet-Westers"
		label val herkomst herkomst
		label var herkomst "Herkomstgroepering"

	*** remerge GBA
		merge 1:m gbaherkomstgroepering using "H:\tussen\gba_tijdelijk.dta", keep (2 3)
		tab gbaherkomstgroepering if _merge==2
		
		drop _merge 
		label var herkomst "Herkomstgroepering obv geboorteland (ouders) in GBA"

	*** first or second migration generation
		destring gbageneratie, gen(generatie)
		label var generatie "Generatie met migratie-achtergrond"
		tab gbaherkomstgroepering if generatie==0 & herkomst!=1

		*assert generatie==0 if herkomst==1
		*assert generatie==1 | generatie==2 if herkomst>1
		recode generatie (0=3)
		label def generatie 1 "Eerste gen." 2 "Tweede gen." 3 "Geen migratie-achtergr."
		label val generatie generatie

	
***********************
*** Save final file ***
***********************

	destring rinpersoon, replace
	compress
	keep rinpersoon herkomst generatie geslacht geboortedatum

	save 	"H:\tussen\gba.dta", replace
	erase 	"H:\tussen\gba_tijdelijk.dta"
