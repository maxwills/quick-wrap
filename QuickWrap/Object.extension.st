Extension { #name : #Object }

{ #category : #'*QuickWrap' }
Object >> execute: aMethod withArgs: args [

	"Calls the evaluation primitive"

	^ aMethod receiver: self withArguments: args executeMethod: aMethod
]
