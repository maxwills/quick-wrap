Class {
	#name : #QuickWrapMethodInDifferentInstance,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapMethodInDifferentInstance class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the prama of this class"
	| proxy wrapperMethod pragma|
	
	pragma := (aMethod pragmas select:[:p| p selector = self handledPragma ]) first.
	
	wrapperMethod := pragma.

	proxy := QuickWrapMethodProxy 
		         onMethod: aMethod
		         delegateHandler: wrapperMethod methodClass
		         selector: wrapperMethod selector.
	proxy install
]

{ #category : #'as yet unclassified' }
QuickWrapMethodInDifferentInstance class >> handledPragma [

	^ #quickWrapWith:
]
