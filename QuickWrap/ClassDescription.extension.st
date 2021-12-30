Extension { #name : #ClassDescription }

{ #category : #'*QuickWrap' }
ClassDescription >> addSlotInOrder: aSlot [

	^self subclassResponsibility
]

{ #category : #'*QuickWrap' }
ClassDescription >> addSlotSecretly: aSlot [

	SystemAnnouncer uniqueInstance suspendAllWhile: [ 
		^ self addSlot: aSlot ]
]

{ #category : #'*QuickWrap' }
ClassDescription >> addSlotSecretlyAndInOrder: aSlot [

	SystemAnnouncer uniqueInstance suspendAllWhile: [ 
		^ self addSlotInOrder: aSlot ] 
]

{ #category : #'*QuickWrap' }
ClassDescription >> addSlotSecretlyAndOrderly: aSlot [

	SystemAnnouncer uniqueInstance suspendAllWhile: [ 
		^ self addSlotInOrder: aSlot ] 
]

{ #category : #'*QuickWrap' }
ClassDescription >> compileSecretly: code [

	"Compile the code without leaving any trace."

	"Because compileSilently: still leave traces in the changes files for classes that reply true to acceptsLoggingOfCompilation"

	^ self compileSecretly: code classified: Protocol unclassified
]

{ #category : #'*QuickWrap' }
ClassDescription >> compileSecretly: code classified: protocol [

	"Compile the code without leaving any trace."

	"Because compileSilently: still leave traces in the changes files for classes that reply true to acceptsLoggingOfCompilation"

	SystemAnnouncer uniqueInstance suspendAllWhile: [ 
		self
			compile: code
			classified: protocol
			withStamp: nil
			notifying: nil
			logSource: false ]
]
