This series of workshops aims to get you beyond the basics.
We deliberately don't call it "Advanced R".  "Advanced" suggests 
it is for the elite R users, the "1%". My firm belief is that the
material we cover here is for any R user that uses R regularly,
i.e. more than a once-off interaction.

My premise is simple. If you will be using R (or any general
purpose proramming language or software system) for a year or more 
of your career, then you are better off learning how to use it properly.
It will save time in the long run and make you much more productive.
In particular, you can focus on the real problems, not the annoying programming
problems.  

We often think hard about a problem and spend hours or days trying to figure it out.
Along the way, we  look at the problem in different ways, learn many new things.
In Math, we can chase our symbols around the page to prove x = x.
And, in computing/programming, we often spend a long time debugging problems only
to find the issue is a simple error.  From these we learn very little. In fact, we sometimes
"unlearn". By this I mean we think something is correct, then doubt it and assume it is the problem,
undo code, and then much later resolve the problem. However, we have convinced ourselves that what
we thought was the problem but wasn't is now wrong.  So debugging code can be very frustrating and
unrewarding. So we want to minimize the time debugging menial tasks.

Debugging hard problems in code is interesting. There we are 
clarifying our thoughts about different situations, handling special/corner-cases,
debugging different alternative approaches. We are learning as we debug, actually solving rich
problems, not the menial coding aspects.  We are learning about the problem, and sometimes,
learning about more "advanced" features of the programming language. But we are not wasting
time.

We are discussing debugging as a motivation for learning more than the basics of R (or any
programming language).  There are two comments in this regard.
1. People typically don't learn either the debugging tools or the art/process of debugging, and this
   is a mistake that is  a symptom of not investing time to save time.
2. The best approach to debugging is to avoid it as much as possible and this is best done by having as thorough an
   understanding  of the computational model with which you are working.  This means
   understanding/mastering the programming
   language first, then the libraries/packages and their functions that you are using, and then the
   problem  you are solving.  If you are dealing with syntax or basic programming problems,
   these are a big distraction from the main goal. So we aspire to make programming as transparent
   as possible so that we can focus on the real problem(s).
   

People resist learning debugging tools. The presence of these tools in IDEs (Integrated
Development Environments) such as RStudio help reduce this resistance. However,
people continue to resist taking control of these tools to help them be more productive.
One of the explanations is that they are more focused on solving the actual problem 
at hand rather than taking a detour to learn the debugging functionality. 
This is a very reasonable, human approach. Unfortunately, it means we never really take the time
as each occurrence of a bug/problem results in the same logic.  Solving the immediate problem and
not learning a better, more efficient general approach leads to many local optima, but not a global
optimum.
Furthermore, adding print statements (using `print()`, `cat()`, `message()`, ...)
is the age-old convenient, seemingly expedient debugging  technique. So the "okay" is the enemy of
the good, and certainly of the better.


Imagine somebody teaching differentiation with a sequence of rules
+ x^2 -> 2x
+ x^3 -> 3x^2
+ 4x^3 -> 12x^2
+ sin(x^2) = 2 cos(x^2)


Think about learning a language. 
We learn some words (vocabulary), a few phrases.  We can create new phrases
by replacing individual words from our vocabulary.  However, we cannot construct
new sentences.  We are limited to the structures/forms we have been shown. 
TO go beyond this, we need to learn grammar.  Once we have the grammatical
rules, we have the mechanisms to compose.

What are the equivalents for a programming language.
We need a basic phrase. In R, this is a call:
```
summary(x)
mean(x,  na.rm = TRUE)
```
Everything in R is a call (except just referring to a variable by name, i.e. `x`)
(Almost) Every call is `functionName( argument1, argument2)`
Some calls use named arguments (`na.rm = TRUE`).
Other calls use a convenient syntax
```
x[1]
mtcar$mpg
1:3
```
But these are actually regular calls 
```
`[`(x, 1)
`$`(mtcar, mpg)
`:`(1, 3)
```
(Go ahead and cut and paste each of these and you'll see you get the same result.)

We can compose phrases


## Scope





One of the most important aspects of a programming language is 
where variables used in a command are found/resolved.
A very lose analogy with natural languages is how 
pronouns map back to actual nouns.
Consider
```
Different statistical methods often give the same basic predictions, but not
the same parameter estimates. These cause confusion.
```
To what does the "these" refer?






## Goals
+ Get better at reading and understanding other people's code 
+ Fix problems in code.
+ Write better code
+ Write reusable, customizable code
+ Write packages
   + Not necessarily for use by others or publish on CRAN, but why not?
+ Write extensible code
+ Write more efficient (faster, less memory hungry) code.

   

# Workflow

First thing is to recognize what your primary aspirations are.
+ Are you  
+ issuing R commands and getting results one command at a time.
+ incrementally building scripts of commands
+ creating reusable scripts that can be parameterized with different data sets, settings, options.
+ writing functions
+ writing packages 
  + for your own reuse
  + for others
  
  
  
  
### Write scripts to work for others to use
This means not hardcoding directories, e.g.
```
read.csv("C:/Users/jane/Desktop/")
```
Why? Because nobody other than you can run this code.
That means nobody can help you debug this code, except on your machine!
In fact, you can't even run this code on another machine without exactly the same
login and file setup.
We want to be able to see if this works for others and is specific to you, or a general
problem with the code? Perhaps it is specific to Windows and not Linux or OSX?
Or perhaps we want to see if it runs on a machine with more RAM? a newer OS? R? packages?
(We can check the last 2 of these on our machine if we know how to install and use
two different versions of R and R libraries of packages.)

So instead of 
```
a = read.csv("C:/Users/jane/Desktop/A.csv")
b = read.csv("C:/Users/jane/Desktop/B.csv")
```
we should use
```
BaseDir = "C:/Users/jane/Desktop/"
a = read.csv(file.path(BaseDir, "A.csv"))
b = read.csv(file.path(BaseDir, "B.csv"))
```
This still hard-codes the path,
but at least in only one location.
By putting the definition of BaseDir at the top of the file, another user
(or same user on another machine) can see they need to change this before running the code.

We can do better than this. We can 
1. check whether the directory exists before we do any computations and issue an error if  it doesn't
1. conditionally define the value BaseDir only if it hasn't already been defined.

The point of the second approach is to allow another user override the value of `BaseDir`
before the source the R code.


If we read files from 2 or more directories, we would use the same
approach for each.


+ Use symbolic links

#### A Better Approach for Finding External Files
When the data are small to moderate size, a better approach than specifying paths is to put the 
data into a package.   (It makes sense to put the code into the package also.)
Let's call the package `DH`.
We can put the data files into the data/ directory. Then we can use the 
`data()` function to load each file and R will find it for us without us needing to specify
the path to the directory.

Alternatively, we can put the data into any directory under the inst/ directory in our package,
say `inst/xlsx/effort.xlsx`.
When we install the package, the directory xlsx and its contents will be copied into the installed directory structure.
Then, we can refer to these files in a machine- and location-independent way with
```
f = system.file("xlsx/effort.xlsx", package = "DH")
d = read_excel(f)
```

This, of course, works for any file type, not just an xlsx file. The key point here
is how we find the file, not how we read it.



### Packages

We build the DH package.
Let's see if we can install it.
```
R CMD INSTALL .
```
or from within R
```
install.packages(".", repos = NULL)
```

The output is
```
Installing package into ‘/Users/duncan/Rpackages’
(as ‘lib’ is unspecified)
* installing *source* package ‘DH’ ...
** data
** inst
** help
No man pages found in package  ‘DH’ 
*** installing help indices
** building package indices
** testing if installed package can be loaded
* DONE (DH)
```

So this worked and we can use the package
```
library(DH)
data("effort")
```


#### Checking a Package For Errors



Let's check the package for detectable errors.
If we just run R CMD check from the command line, we get

```
R CMD check .
```
```
* using log directory ‘/Users/duncan/DSI/Workshops/Summer18/DavidHernandez/DH/..Rcheck’
* using R version 3.4.4 (2018-03-15)
* using platform: x86_64-apple-darwin17.4.0 (64-bit)
* using session charset: UTF-8
* checking for file ‘./DESCRIPTION’ ... OK
* this is package ‘DH’ version ‘0.1-0’
* checking package namespace information ... OK
* checking package dependencies ... OK
* checking if this is a source package ... NOTE
Subdirectory ‘DH.Rcheck/DH’ seems to contain an installed version of the package.
* checking if there is a namespace ... OK
* checking for executable files ... WARNING
Found the following executable files:
  .git/objects/0b/ab52fbbaeb9f7b05f6355f2f1f3676ca0c1d65
  .git/objects/0c/9d7d3668883ef768840b5d073030550bb02b74
  .git/objects/21/8f889f3e396154e325f2cdbae4d5ddb1daa7c8
  .git/objects/26/23e510d415fa0388b960689820da4d922f5bce
  .git/objects/43/f4a549a0f9ea43fbd041bb48b291552eb429b1
  .git/objects/45/5809f5acda582e26b35b97a39e0eaa9f3bbdd8
  .git/objects/48/416e51b8f680028c9706807dd010cdea5d8348
  .git/objects/49/b728bcad93fc730bd1f133fb62d92c1c2f5930
  .git/objects/5c/607909af941409944f572067be3a82b0087eea
  .git/objects/5c/839ec8c17861bf09771fc46afed4d11c45aebe
  .git/objects/6c/1346c25669ff5938f37ce39a1ad751224a32af
  .git/objects/85/4adc4ee3a053defa1ede0589f41d94a8d20f2c
  .git/objects/94/e15642a104b44d053874a334ac0968f707f543
  .git/objects/b1/ddd656ce79431300f553a793fe0a5a7acaffbf
  .git/objects/b6/857c7d708619d5f88add6e4f765d7327acd84a
  .git/objects/c4/2df5b1993ca405249f8a9485d733270127cd48
  .git/objects/cc/87308a56fda7c5e745039dc6428bd139cf972f
  .git/objects/d0/bc79fb489a9e7a1243f44bd3c632ebaea4b2d6
  .git/objects/d8/bc4666c0980bb97722f7b0e25f522820694351
  .git/objects/de/0fb5845df96f348ef705ddf4fe80d901bedf88
  .git/objects/ef/1bf8dbea46124c6258664f670163929fdd3e5d
  .git/objects/f4/67c45feb250221d7489f6505805fcab939d0de
  .git/objects/f5/400c30060698b7569e0185e9e72f038a7e32c9
Source packages should not contain undeclared executable files.
See section ‘Package structure’ in the ‘Writing R Extensions’ manual.
* checking for hidden files and directories ... NOTE
Found the following hidden files and directories:
  ..Rcheck
  .git
These were most likely included in error. See section ‘Package
structure’ in the ‘Writing R Extensions’ manual.
* checking for portable file names ... WARNING
Found the following files with non-portable file names:
  DH.Rcheck/00_pkg_src/DH/inst/scripts/tidy function.R
  DH.Rcheck/DH/scripts/tidy function.R
  inst/scripts/tidy function.R
These are not fully portable file names.
See section ‘Package structure’ in the ‘Writing R Extensions’ manual.
* checking for sufficient/correct file permissions ... OK
* checking whether package ‘DH’ can be installed ... OK
* checking installed package size ... OK
* checking package directory ... OK
* checking DESCRIPTION meta-information ... NOTE
Deprecated license: BSD
Checking should be performed on sources prepared by ‘R CMD build’.
* checking top-level files ... OK
* checking for left-over files ... OK
* checking index information ... OK
* checking package subdirectories ... WARNING
Found the following directories with names of check directories:
  ./..Rcheck
  ./DH.Rcheck
Most likely, these were included erroneously.
* checking whether the package can be loaded ... OK
* checking whether the package can be loaded with stated dependencies ... OK
* checking whether the package can be unloaded cleanly ... OK
* checking whether the namespace can be loaded with stated dependencies ... OK
* checking whether the namespace can be unloaded cleanly ... OK
* checking loading without being on the library search path ... OK
* checking for missing documentation entries ... WARNING
Undocumented data sets:
  ‘BothSpecies’ ‘effort’
All user-level objects in a package should have documentation entries.
See chapter ‘Writing R documentation files’ in the ‘Writing R
Extensions’ manual.
* checking contents of ‘data’ directory ... OK
* checking data for non-ASCII characters ... OK
* checking data for ASCII and uncompressed saves ... OK
* checking examples ... NONE
* checking PDF version of manual ... OK
* DONE

Status: 4 WARNINGs, 3 NOTEs
See
  ‘/Users/duncan/DSI/Workshops/Summer18/DavidHernandez/DH/..Rcheck/00check.log’
for details.
```

One of the problems is that the R CMD check tool is
using the contents of our working directory.
This includes extraneous files and directories such as ..Rcheck and .git 
that we want it to ignore.  While R supports
both a .Rbuildignore and .Rinstignore file, R does not provide a .Rcheckignore file
for specifying what files and directory to ignore  when running `R CMD check`.
Instead, we first `R CMD build` the tar.gz for the package (i.e., the source version of the package)
and then run `R CMD check` on that. The `build` step arranges the files into an R package structure.
It does consult the .Rbuildignore file and so we can discard any files and directories
that we have just for our own development use. This includes ..Rcheck and .git.

We use a text editor to create the .Rbuildignore file in the top-level directory of the
package (beside the DESCRIPTION file).
Each line in the .Rbuildignore file is a regular expression identifying a file name pattern to match.
Note that, with all regular expressions, we can over match and exclude some files. This is especially
true when the pattern contains special characters such as . and other metacharacters in the regular expression
language.

Our .Rbuildignore is 
```
..Rcheck
.git
```

We now build the package and check the resulting .tar.gz file:
```
R CMD build .
R CMD check DH_0.1-0.tar.gz
```
```
* using log directory ‘/Users/duncan/DSI/Workshops/Summer18/DavidHernandez/DH/DH.Rcheck’
* using R version 3.4.4 (2018-03-15)
* using platform: x86_64-apple-darwin17.4.0 (64-bit)
* using session charset: UTF-8
* checking for file ‘DH/DESCRIPTION’ ... OK
* this is package ‘DH’ version ‘0.1-0’
* checking package namespace information ... OK
* checking package dependencies ... OK
* checking if this is a source package ... OK
* checking if there is a namespace ... OK
* checking for executable files ... OK
* checking for hidden files and directories ... OK
* checking for portable file names ... WARNING
Found the following file with a non-portable file name:
  inst/scripts/tidy function.R
These are not fully portable file names.
See section ‘Package structure’ in the ‘Writing R Extensions’ manual.
* checking for sufficient/correct file permissions ... OK
* checking whether package ‘DH’ can be installed ... OK
* checking installed package size ... OK
* checking package directory ... OK
* checking DESCRIPTION meta-information ... NOTE
Deprecated license: BSD
* checking top-level files ... OK
* checking for left-over files ... OK
* checking index information ... OK
* checking package subdirectories ... OK
* checking whether the package can be loaded ... OK
* checking whether the package can be loaded with stated dependencies ... OK
* checking whether the package can be unloaded cleanly ... OK
* checking whether the namespace can be loaded with stated dependencies ... OK
* checking whether the namespace can be unloaded cleanly ... OK
* checking loading without being on the library search path ... OK
* checking for missing documentation entries ... WARNING
Undocumented data sets:
  ‘BothSpecies’ ‘effort’
All user-level objects in a package should have documentation entries.
See chapter ‘Writing R documentation files’ in the ‘Writing R
Extensions’ manual.
* checking contents of ‘data’ directory ... OK
* checking data for non-ASCII characters ... OK
* checking data for ASCII and uncompressed saves ... OK
* checking examples ... NONE
* checking PDF version of manual ... OK
* DONE

Status: 2 WARNINGs, 1 NOTE
See
  ‘/Users/duncan/DSI/Workshops/Summer18/DavidHernandez/DH/DH.Rcheck/00check.log’
for details.
```
