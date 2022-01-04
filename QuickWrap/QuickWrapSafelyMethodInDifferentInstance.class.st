Class {
	#name : #QuickWrapSafelyMethodInDifferentInstance,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapSafelyMethodInDifferentInstance class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the pragma of this class"

	| proxy pragma wrapperClassName wrapperSelector |
	pragma := self getHandledPragma: aMethod.

	wrapperClassName := pragma arguments first.
	wrapperSelector := pragma arguments second.

	proxy := QuickWrapSafeMethodProxy
		         onMethod: aMethod unproxifiedMethod
		         delegateHandler: [ self class environment at: wrapperClassName ]
		         selector: wrapperSelector.
	proxy install
]

{ #category : #'as yet unclassified' }
QuickWrapSafelyMethodInDifferentInstance class >> handledPragma [

	<qwpAddPragmaToAutocompletion>
	^ #qwpWrappedSafelyBy:selector:
]
