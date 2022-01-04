Extension { #name : #Pragma }

{ #category : #'*QuickWrap' }
Pragma class >> fullListOfAllNamed: aSymbol [

	"Answer a collection of all pragmas whose selector is aSymbol."

	"without the check to know if it is installed or not. For compatibility with QuickWrap pragma based Proxies."

	| pragmas |
	pragmas := self pragmaCache at: aSymbol ifAbsent: [ ^ #(  ) ].
	"if there are none, we can remove the entry in the cache"
	pragmas ifEmpty: [ 
		self pragmaCache removeKey: aSymbol ifAbsent: [  ] ].
	"we check if the pragma is really from an installed method 
	(others will be cleaned up by the gc when the method is garbadge collected)"
	^ pragmas asArray
]
