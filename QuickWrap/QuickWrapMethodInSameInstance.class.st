Class {
	#name : #QuickWrapMethodInSameInstance,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapMethodInSameInstance class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the pragma of this class"

	| proxy pragma wrapperSelector |
	pragma := self getHandledPragma: aMethod.

	wrapperSelector := pragma arguments first.

	proxy := QuickWrapMethodProxy
		         onMethod: aMethod unproxifiedMethod
		         delegateHandler: aMethod unproxifiedMethod methodClass soleInstance
		         selector: wrapperSelector.
	proxy install
]

{ #category : #'as yet unclassified' }
QuickWrapMethodInSameInstance class >> handledPragma [

	<qwpAddPragmaToAutocompletion> 
	^ #qwpWrapWith:
]
