Extension { #name : #CompiledMethod }

{ #category : #'*QuickWrap' }
CompiledMethod >> addPragma: pragmaString [

	"Adds the pragma to the method source code, then recompiles it. Doesn't check if exists."

	QwPragmaUtil default addPragma: pragmaString toMethod: self
]

{ #category : #'*QuickWrap' }
CompiledMethod >> removePragmaNamed: pragmaSelector [

	"Adds the pragma to the method source code, then recompiles it. Doesn't check if exists."

	QwPragmaUtil default
		removePragmaNamed: pragmaSelector
		fromMethod: self
]
