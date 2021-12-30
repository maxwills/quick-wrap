Extension { #name : #Metaclass }

{ #category : #'*QuickWrap' }
Metaclass >> addSlotInOrder: aClassSlot [

	^self instanceSide addClassSlotInOrder: aClassSlot
]
