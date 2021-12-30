Class {
	#name : #QuickWrapForPragmaAutocompletionToTargetHolder,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletionToTargetHolder class >> createMethodHeaderForSelector: aSymbol [

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
QuickWrapForPragmaAutocompletionToTargetHolder class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the pragma of this class"

	| pragma pragmaHandledPragma holderClassName holderClass |
	pragma := (aMethod pragmas select: [ :p | 
		           p selector = self handledPragma ]) first.

	pragma method selector = #handledPragma ifFalse: [ ^ self ].
	holderClassName := pragma arguments first.
	holderClass := self environment at: holderClassName ifAbsent: [ 
		               self inform:
			               'QuickWrap handling: ' , self handledPragma
			               , ' - Class ' , holderClassName , ' not found,'.
		               ^ self ].
	"No proxy is installed in this case. We only execute a post compilation code"
	pragmaHandledPragma := pragma method methodClass instanceSide
		                       handledPragma.

	(pragmaHandledPragma includes: $:)
		ifTrue: [ 
			| methodHeader |
			methodHeader := self createMethodHeaderForSelector:
				                pragmaHandledPragma.
			holderClass compileSecretly: methodHeader , '
		^ #methodOnlyForAutocompletion' ]
		ifFalse: [ 
			holderClass compileSecretly: pragmaHandledPragma , '
		^ #methodOnlyForAutocompletion' ]
]

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletionToTargetHolder class >> handledPragma [

	<qwpAddPragmaToAutocompletion>
	^ #qwpAddPragmaToAutocompletionIn:
]

{ #category : #'as yet unclassified' }
QuickWrapForPragmaAutocompletionToTargetHolder class >> testCreateMethodHeaderForSelector [

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
