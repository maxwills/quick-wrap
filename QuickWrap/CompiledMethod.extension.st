Extension { #name : #CompiledMethod }

{ #category : #'*QuickWrap' }
CompiledMethod >> addPragmaExpression: pragmaString [

	"Adds the pragma to the method source code, then recompiles it. Doesn't check if exists."

	QwPragmaUtil default addPragma: pragmaString toMethod: self
]

{ #category : #'*QuickWrap' }
CompiledMethod >> detectPragmaIndex: aSelector [

	^ self pragmas detectIndex: [ :p | p selector == aSelector ]
]

{ #category : #'*QuickWrap' }
CompiledMethod >> isInstalledOrProxified [

	self methodClass ifNotNil: [ :class | 
		self selector ifNotNil: [ :selector | 
			| installedMethod |
			installedMethod := class compiledMethodAt: selector ifAbsent: nil.
			^(self == installedMethod or: [ 
				self == installedMethod unproxifiedMethod ] )] ].
	^ false
]

{ #category : #'*QuickWrap' }
CompiledMethod >> removePragmaNamed: pragmaSelector [

	"Adds the pragma to the method source code, then recompiles it. Doesn't check if exists."

	QwPragmaUtil default
		removePragmaNamed: pragmaSelector
		fromMethod: self
]

{ #category : #'*QuickWrap' }
CompiledMethod >> sourceCodeLines [

	^ self sourceCode splitOn: String cr
]
