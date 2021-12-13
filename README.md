# Merging in comments from a SurveyCTO Survey

## Overview

ctomergecom is a Stata command for merging SurveyCTO comment data with imported Stata datasets.


## Installation

```stata
* ipacheckscto can be installed from github

net install ctomergecom, all replace ///
from("https://raw.githubusercontent.com/c4ed-mannheim/commentsmerge/main")


```

## Syntax
```stata

Syntax: 
ctomergecom, [FName(string) Cvar(string) Mediapath(string)]


Options :
FName (string): 	- The field name of the comments function in SurveyCTO
Cvar (string): 		- The name of the variable generated for the comments uses the specifiedstring.
						 - if not specified, the default name is _comx
Mediapath (string):	- The path of the exported mediafiles 					 

```

## Example Syntax
```stata

* Merge in comments 
ctomergecom, FN(comments_questions) Cvar(coms) Mediapath()

```

