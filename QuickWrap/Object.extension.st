Extension { #name : #Object }

{ #category : #'*QuickWrap' }
Object >> execute: aMethod withArgs: args [

	"Calls the evaluation primitive"

	 "^ aMethod receiver: self withArguments: args executeMethod: aMethod" "non P9 compatible"
	^ self withArgs: args executeMethod: aMethod "P9 compatible"
]

{ #category : #'*QuickWrap' }
Object class >> qwRegenerateSubCache [

	"(Re)Creates the sub cache completely. Use this to clean up unused methods in the subcache"

	<script>
	(SubCache classHasSubCache: self) ifTrue: [ 
		SubCache regenerateSubCacheForClass: self ]
]
