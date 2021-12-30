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

