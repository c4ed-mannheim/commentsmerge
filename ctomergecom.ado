/*

** SurveyCTO functionality -comments- allows users to enter comments for specific field (screen). They are exported
as csv media files when exporting the data from the SurveyCTO server. This programme merges the comments into the 
main dataset to allow for easier review.

Syntax: ctomergecom, options


Options :
FName (string): 	- The field name of the comments function in SurveyCTO
Cvar (string): 		- The name of the variable generated for the comments uses the specifiedstring.
						 - if not specified, the default name is _comx
Mediapath (string):	- The path of the exported mediafiles 					 


						 
Notes:

Version: 1.0 
Changelog:
29/11/2021: 	v0.1: 	First Working version


Known Bugs:


To do:
- Check for presence of cvar - will break if already exists
- Check for length of variable if _`cvar' added to - will break if too long
- Check that cvar is acceptable - e.g. doesn't start with letter or has space
- Check that media path exists
- Tidy up code
- Once working - run quietly

Notes:
-

Author:
Nathan Sivewright, C4ED
*/

capture program	drop ctomergecom
program ctomergecom
syntax, [FName(string) Cvar(string) Mediapath(string)]

local dir `c(pwd)'

tempfile main_data
save `main_data'
* [using/]
* [LName(string)] IDColumn(string) VAColumn(string) [Add(string)] [IF(string)] [dropvac] [defonly] [proper]

/*
quietly{	
	preserve
	local flgLoad = 0 
	if "`using'" != ""{
		*load using
		if regexm("`using'",".csv")==1 {
			insheet using `"`using'"', clear comma case
			local flgLoad = 1
		}

		if regexm("`using'",".dta")==1 {
			use `"`using'"', clear
			local flgLoad = 1
		}
		if regexm("`using'",".xlsx")==1 | regexm("`using'",".xls")==1 {
			import excel using `"`using'"', clear firstrow
			local flgLoad = 1
		}

		if !`flgLoad'{
			cap use `"`using'"', clear
			if _rc{
				di as err `"Failed to load `using'"'
				ex 198
			}
		}
*/
************************************************************************************************************************************************************************
********************************************************************************
* MERGING IN COMMENTS
********************************************************************************

* Nathan October 2021

/* In this do-file, we will take the individual comments files in csv form that is exported by SurveyCTO Desktop, clean and append them to
allow for merging with the main dataset. The comment variables (_comx) will be then ordered after the original variables


*** TO DO
- If more than one comment per variable - BREAKS
- Check to make sure no variable names also end in _comx
- Find a better solution for multi-response options and ordering - because the comment is saved as conneted to mutli_var but the variables in the dataset are multi_var_1 etc. 

*** ISSUES FIXED
- If line spaces in comment - creates a new row = FIX: Delete if _comx is empty





*/
preserve

	*set default comments variable name	
	if "`cvar'" == "" {
	local cvar "comx"
	di "No comment variable name specified - will use _comx"	
	}
	
	else {
		local scheck = substr("`cvar'", 1, 1)	
		local schecko = regexm("`scheck'", "[a-zA-Z]")
		local anyspec regexm("`cvar'", "[^a-zA-Z0-9]")
		local varl = strlen("`cvar'")
		if `schecko' !=1 {
		di as err "Option cvar must start with alphabetical character"
		ex 198	
		} 
		if `varl' > 31 {
		di as err "Option cvar has too many characters (max 31)"
		ex 198	
		}
		if `anyspec' == 1 {
		di as err "Option cvar cannot have a special character in"
		ex 198		
		}
	}
	
	if "`fname'" == "" {
	di as err "No comment field name specified - Check SurveyCTO form and enter in option"
	ex 198
	}
	
	if "`mediapath'" == "" {
	di as err "Media path specified - Check where media was exported to and enter in option"
	ex 198
	}
	
	local scheck = substr("`cvar'", 1, 1)

/*
********************************************************************************
* Enter Macros
********************************************************************************
local mediapath "C:\Users\NathanSivewright\Desktop\00_Archive\Projects\Comments_Merge_Test\media" // Enter media path on local
*
*local main_data "C:\Users\NathanSivewright\Desktop\00_Archive\Projects\Comments_Merge_Test\p20204c_sme_2021_v6nathan.dta" // Enter main dataset path
local main_data_comments "C:\Users\NathanSivewright\Desktop\00_Archive\Projects\Comments_Merge_Test\p20204c_sme_2021_v6nathan_withcomments.dta" // Enter path for where you want to save data with comments
global i=0 // Do not change
global fname "comments_questions" // Enter the variable name for the comments function
local nathan "comx"
*/
cd "`mediapath'"
********************************************************************************
* Checks 
********************************************************************************
* Check for existence of variable already ending in _comx

*quietly {
********************************************************************************
* Cleaning up the individual comment files
********************************************************************************
global i=0 // Do not change

local files : dir "`mediapath'" file "Comments*.csv", respectcase	
local total_ : word count  `files' // counts the total number of files

if `total_' > 0 {
	
foreach file in `files'{	
	import delimited using "`file'", varnames(1) stringcols(2) bindquotes(strict) clear // Import each csv file in media folder
*	capture confirm numeric variable comment // Check for rogue blank comments - will cause error as stata thinks they are numeric when appending
*	    if !_rc {
*			tostring comment, replace // makes any blank a string variable
*		}
di "`file'"
gen variable = substr(fieldname, strrpos(fieldname,"/")+1, .) // Taking the variable name
rename comment _`cvar' // Prepping for reshape
replace _`cvar' = "[EMPTY COMMENT BY ENUMERATOR]" if _`cvar' == "" & variable!=""
drop if _`cvar' == ""

local singvar = ""
local dupvar = ""

count 
if `r(N)'>0 {


gen id=1 // Prepping for reshape
bysort variable: gen counter=_n
drop fieldname // Not necessary
reshape wide @_`cvar', i(id counter) j(variable) string // Reshaping to wide


count
if `r(N)'>1 {

ds id counter, not 
foreach var of varlist `r(varlist)' {
	distinct `var'
		if `r(ndistinct)'==1 {
			local singvar `singvar' `var'
		}
		if `r(ndistinct)'>1 {
			local dupvar `dupvar' `var'
		}
} 

tempfile allvar
save `allvar'

use `allvar', clear

keep counter id `singvar'
foreach var of varlist `singvar' {
drop if `var'=="" // put this in a loop for each single variable
duplicates drop `var', force // removes duplicate cases
}
tempfile singlevar
save `singlevar'

if "`dupvar'" != "" {
use `allvar', clear
keep id counter `dupvar'
reshape wide `dupvar', i(id) j(counter)

tempfile duplciatevar
save `duplciatevar'
merge 1:1 id using `singlevar', nogen
}
}

drop id


gen `fname'="media\"+"`file'" // Aligning with the commentx variable in the dataset to merge
global i=${i}+1 // Naming each file as a tempfile to prepare for appending
tempfile comment_$i
save `comment_$i' // Creating a tempfile for each csv

}
}


********************************************************************************
* Appending the tempfiles
********************************************************************************
/// THERE PROBABLY IS A CLEANER WAY OF DOING THIS!!
forval x = 1/`total_' { // For each of the total tempfiles
if `x'==1 { // If the first we don't want to append
use `comment_`x'', clear
tempfile all_comment
save `all_comment'
}
if `x'>1 {
use `all_comment', clear
di "`x'"
append using `comment_`x''
save `all_comment', replace
}
}

*}

********************************************************************************
* Checks before merging with the main dataset
********************************************************************************
use `main_data', clear
duplicates tag `fname', gen(dup_`fname') // Flagging cases of duplicates 

drop if dup_`fname'>0

count if dup_`fname'>1 // Flag if duplicates in main data
if `r(N)'>0 {
 n: di as error "There are duplicate cases in the main data - fix these before merging in"
 ex
}

use `all_comment', clear
duplicates tag `fname', gen(dup_`fname')
count if dup_`fname'>1 // Flag if duplicates in main data
if `r(N)'>0 {
 n: di as error "There are duplicate cases in the comments data - fix these before merging in"
 ex
}

********************************************************************************
* Merging with the main dataset
********************************************************************************

use `main_data', clear
count 
local obs_count_before = `r(N)'  // Counts the number of observations in main data before merge

keep if `fname'=="" 
tempfile no_comments
save `no_comments'  // Make a tempfile with observations with no comments - as these won't merge

use `main_data', clear
drop if `fname'=="" // Keep only cases with comments
merge 1:1 `fname' using `all_comment', keep(1 3) nogen // Merge with the appended comments tempfile
append using `no_comments' // Append the cases without comments
count 
local obs_count_after = `r(N)' // Counts the number of observations in main data after merge

if `obs_count_before' != `obs_count_after' { // Flag if the number of obs before is different from after merge - shouldn't happen
	di "You have lost or gained some observations from the merge - this needs to be checked"
}

********************************************************************************
* Ordering comment variables next to main variable
********************************************************************************

foreach var of varlist *_`cvar' *_`cvar'* {
local o_`var' = substr("`var'", 1, strrpos("`var'", "_")-1) // Takes the original variable name
capture confirm variable `o_`var'', exact
if !_rc {
order `var', after(`o_`var'') // Puts comment variable after original
}
else {
	capture confirm variable `o_`var''_1, exact
	if !_rc {
order `var', before(`o_`var''_1) // Puts comment variable before the first of the roster
	}
	else {
		di "variable doesn't exist, `var' will be at end of dataset"
	}
}
}

drop counter
********************************************************************************
* Saving version with comments
********************************************************************************

*save "`main_data_comments''", replace
}

else {
	di "No comments - nothing will be merged in"
}

restore, not

cd "`dir'"
end

