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

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletion class >> testCreateMethodHeaderForSelector [

	"Put in a test case with other tests"

	<script>
	| res expected input |
	input := #my:method:.
	expected := 'my: arg1 method: arg2 '.
	res := self createMethodHeaderForSelector: input.
	self assert: expected asString = res.

	input := #my:.
	expected := 'my: arg1 '.
	res := self createMethodHeaderForSelector: input.

	self assert: expected asString = res.

	input := #my:method:with:arguments:.
	expected := 'my: arg1 method: arg2 with: arg3 arguments: arg4 '.
	res := self createMethodHeaderForSelector: input.

	self assert: expected asString = res.

	self inform: 'Test passed'
]
