Class {
	#name : #QuickWrapMethodInSameInstance,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapMethodInSameInstance class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the prama of this class"

	| proxy pragma wrapperSelector |
	pragma := (aMethod pragmas select: [ :p | 
		           p selector = self handledPragma ]) first.

	wrapperSelector := pragma arguments first.

	proxy := QuickWrapMethodProxy
		         onMethod: aMethod
		         delegateHandler: aMethod methodClass soleInstance
		         selector: wrapperSelector.
	proxy install
]

{ #category : #'as yet unclassified' }
QuickWrapMethodInSameInstance class >> handledPragma [
 
	^ #quickWrapWithSelector:
]
