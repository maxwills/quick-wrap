# quick-wrap

A method wrapping system based on pragmas, based on MethodProxies lib (Good stuff).

```Smalltalk
Metacello new
    baseline: 'QuickWrap';
    repository: 'github://maxwills/quick-wrap:main';
    load.
```

*Adds "dynamic behavior" to pragmas.*  

To install the compilation hooks, execute:
```Smalltalk
QuickWrap installQuickWrapSystem
```
Previous code will make pragmas "active".

To uninstall the hooks, execute:
```Smalltalk
QuickWrap uninstallQuickWrapSystem
```
Previous code will make pragmas "inactive".

Note that the pragmas can be activated only if the code is compiled when the hooks are installed. 
If your code was compiled before installing quickwrap system, then run after installation:
```Smalltalk
QuickWrap refreshAllWrappers
```
The previous code will recompile all QuickWrap related pragmas methods.

Completely experimental. Use at your own risk.
As a personal note: Debugging errors related to the compilation hooks might be not easy. Now, if you you have a crashing debugger because it relied on quickWrap relaed code to open, then I really wish you good luck.


Requires MethodProxies lib, which is installed automatically when using the provided baseline.

##  Examples

### Method Wrapping using QuickWrap

Example of creating a method that surrounds the result of another method, via quick wrap.

```Smalltalk 
MyObject class >> echo: aString

   "This is your original method"

   ^ aString
```

The code `MyObject echo: 'Hello'` outputs the string 'Hello' when executed.

You want to "wrap it" so it will return a string surrounded by parentheses. 
You can do it like this:

1. Modify your code to:

```Smalltalk 
MyObject class >> echo: aString
    
    "add the QuickWrapPragma (qwp) like this"
   <#qwpWrapWith: #myParenthesesWrapper:arguments:> 

   ^ aString
```

2. Create the wrapping method like this.

```Smalltalk
MyObject class >> myParenthesesWrapper: method arguments: args

   "The wrapped method must be called explicitly"

   ^ '(',(method executeWithArgs: args) ,')'
```

The code `MyObject echo: 'Hello'` now outputs the string '(Hello)' when executed.
The instrumentation happens immediately upon compilation.
To remove the instrumentation, remove the pragma.

## Why?

Code instrumentation is "volatile". 
If the instrumented code is recompiled it will lose the instrumentation. 
Additionally, it is difficult to know and track what code is instrumented and by who. 

Quickwrap solves all those problems. 

By declaring instrumentation via pragmas, the instrumentation persist through code recompilation. 
Also, the pragmas hints what code is instrumenting the instrumented method.

