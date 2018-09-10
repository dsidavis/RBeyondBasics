

# Best Practices

Make the code as usable by others as possible.
This will allow them to help you debug the code, for example.

1. Don't hard-code paths to files.
1. Consider making the data available via a URL. Or download it once into the current directory
   and only conditionally retrieve it by first checking if the file exists.  Add this code to the
   start of the script, making it self-contained.
1. Don't cleanup the work space (e.g. with `rm(list = ls())`)
1. Don't use `require()` to load a package; instead, use `library()`.
1. Only load packages you actually need.
1. Ideally, start the script with programmatically checking if the necessary packages are available,
    and have code that installs the missing packages if they are not present.
	+ Don't install each run of the script, but check each time which are missing.
1. Write functions and have the script use those functions
    + Then test each of those functions separately.
1. Create a package.
1. Put the data in the package.
	

