# Best Practices for Writing Functions

+ Don't Repeat Yourself.
   + Avoid repeating the same code, or the same code with only one/two variable(s) changed.
+ Avoid global variables in the body of the function.
   + Always use codetools::findGlobals(fun, FALSE)$variables
+ When using a global variable, make it the default value of a parameter/formal argument in the
  function, allowing it to be overidden by the caller.
+ Check the inputs are what the function can deal with.
   + Call stop() with a meaningful error message otherwise.
   + Better yet, use an error condition with a custom class when it makes sense.
+ Keep functions short
   + Combine related lines into sub-functions.
+ Define sub-functions separately/outside of the main function unless using a closure (e.g. using
  `<<-`)
+ Write tests for each function. 
   + Add calls to stopifnot() to raise an error if results aren't correct.
+ Consider adding parameters to allow caller to provide intermediate values that the function
  ordinarily calculates.
   + Simplifies and speeds testing
   + Makes more flexible.
   + Lift code from body to parameters with default values being the original computations.
+ Use methods, rather than complicated if-else statements for different combinations of input types.   
+ When creating "better" (faster, less memory) versions of functions, make certain give the same
  results.
    + Reuse the original tests.
+ Export fujnctions via NAMESPACE of the functions you want end-users to see.
