Class {
	#name : #QwPragmaUtil,
	#superclass : #Object,
	#classVars : [
		'default'
	],
	#category : #'QuickWrap-Utils'
}

{ #category : #accessing }
QwPragmaUtil class >> default [

	^ default
]

{ #category : #initialization }
QwPragmaUtil class >> initialize [

	default := self new
]

{ #category : #testing }
QwPragmaUtil >> addPragma: string toMethod: method [

	"Note that the string contains the pragma full specification(ie, the selector with paramaters)"

	"Adds the pragma described in the string to the sourceCode of the method. Then, it will recompile the method."

	| methodNode newPragma |
	methodNode := method ast.
	newPragma := RBParser parsePragma: string.
	methodNode addPragma: newPragma.
	method methodClass compileWithoutEpiceaLogging: methodNode newSource
]

{ #category : #testing }
QwPragmaUtil >> removePragmaNamed: selector fromMethod: method [

	"note that the pragma to be removed is only specified by the selector. Don't include parameters"

	"removes the pragma described in the string to the sourceCode of the method. Then, it will recompile the method."

	"This uses the fact that currently (2022/01/04) pragmas are stored in the method in the same order they are defined."

	| methodNode pragmaIndex |
	methodNode := method ast.
	pragmaIndex := methodNode pragmas detectIndex: [ :p | 
		               p selector == selector ].
	methodNode pragmas removeAt: pragmaIndex.
	method methodClass compileWithoutEpiceaLogging: methodNode newSource
]
