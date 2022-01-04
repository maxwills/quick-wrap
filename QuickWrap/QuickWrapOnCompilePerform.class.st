Class {
	#name : #QuickWrapOnCompilePerform,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapOnCompilePerform class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the pragma of this class"

	"No proxies are installed in this case"

	| pragma selectorToPerform tgtClass |
	pragma := self getHandledPragma: aMethod.
	selectorToPerform := pragma arguments first.
	tgtClass := pragma method methodClass class. "Only class side methods supported"

	(tgtClass respondsTo: selectorToPerform)
		ifTrue: [ tgtClass perform: selectorToPerform ]
		ifFalse: [ 
			self inform:
				'QuickWrap - OnCompilePerform: method not found' , tgtClass name
				, ' ' , selectorToPerform ]
]

{ #category : #'as yet unclassified' }
QuickWrapOnCompilePerform class >> handledPragma [

	<qwpAddPragmaToAutocompletion>
	^ #qwpOnCompilePerform:
]
