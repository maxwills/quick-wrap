"
Lazily evaluates the expresion of the handlers.
"
Class {
	#name : #QuickWrapMethodInDifferentInstance,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapMethodInDifferentInstance class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the pragma of this class"

	| proxy pragma wrapperClassName wrapperSelector |
	pragma := self getHandledPragma: aMethod.

	wrapperClassName := pragma arguments first.
	wrapperSelector := pragma arguments second.

	proxy := QuickWrapMethodProxy
		         onMethod: aMethod unproxifiedMethod
		         delegateHandler: [ self class environment at: wrapperClassName ]
		         selector: wrapperSelector.
	proxy install
]

{ #category : #'as yet unclassified' }
QuickWrapMethodInDifferentInstance class >> handledPragma [
 
	<qwpAddPragmaToAutocompletion>
	^ #qwpWrappedBy:selector:
]
