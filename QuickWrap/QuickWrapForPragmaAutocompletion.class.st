Class {
	#name : #QuickWrapForPragmaAutocompletion,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletion class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the pragma of this class"
	
	| pragma pragmaHandledPragma |
	pragma := (aMethod pragmas select: [ :p | 
		           p selector = self handledPragma ]) first.

	pragma method selector = #handledPragma ifFalse: [ ^ self ].

	"No proxy is installed in this case. We only execute a post compilation code"
	pragmaHandledPragma := pragma method methodClass instanceSide
		                       handledPragma.

	(pragmaHandledPragma includes: ':')
		ifTrue: [ 
			| methodTokens methodHeader |
			methodHeader := ''.
			methodTokens := pragmaHandledPragma splitOn: ':'.
			1 to: methodTokens size do: [ :i | 
				| t |
				t := methodTokens at: i.
				t ifNotEmpty: [ methodHeader := methodHeader, t , ' arg' , (i asString) ,' '] ].
			self compileSecretly: methodHeader , '
		^ #methodOnlyForAutocompletion' ]
		ifFalse: [ 
			self compileSecretly: pragmaHandledPragma , '
		^ #methodOnlyForAutocompletion' ]
]

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletion class >> handledPragma [

	"<quickWrapAddPragmaToAutocompletion>" 
	^ #quickWrapAddPragmaToAutocompletionB 
]
