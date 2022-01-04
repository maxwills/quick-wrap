"
This class defines one of the Post compilation rules for addPragmaToAutocomletion pragma, and also stores autogerated methods in the instance side. The methos in the instance side do nothing, and are there only to provide autoCompletion hints for the registered pragmas.
"
Class {
	#name : #QuickWrapForPragmaAutocompletion,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletion class >> createMethodHeaderForSelector: aSymbol [

	| methodTokens methodHeader |
	methodHeader := ''.
	methodTokens := aSymbol splitOn: ':'.
	1 to: methodTokens size do: [ :i | 
		| t |
		t := methodTokens at: i.
		t ifNotEmpty: [ 
			methodHeader := methodHeader , t , ': arg' , i asString , ' ' ] ].
	^ methodHeader
]

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletion class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the pragma of this class"

	| pragma pragmaHandledPragma |
	pragma := self getHandledPragma: aMethod.

	pragma method selector = #handledPragma ifFalse: [ ^ self ].

	"No proxy is installed in this case. We only execute a post compilation code"
	pragmaHandledPragma := pragma method methodClass instanceSide
		                       handledPragma.

	(pragmaHandledPragma includes: $:)
		ifTrue: [ 
			| methodHeader |
			methodHeader := self createMethodHeaderForSelector:
				                pragmaHandledPragma.
			self compileSecretly: methodHeader , '
		^ #methodOnlyForAutocompletion' ]
		ifFalse: [ 
			self compileSecretly: pragmaHandledPragma , '
		^ #methodOnlyForAutocompletion' ]
]

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletion class >> handledPragma [

	<qwpAddPragmaToAutocompletion>
	^ #qwpAddPragmaToAutocompletion 
]
