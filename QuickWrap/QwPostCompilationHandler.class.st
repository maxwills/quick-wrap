Class {
	#name : #QwPostCompilationHandler,
	#superclass : #Object,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the prama of this class"

	^ self subclassResponsibility
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> handledPragma [

	^ self subclassResponsibility
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> methodHasPragma: method [

	^ method pragmas anySatisfy: [ :p | p selector == self handledPragma ]
]
