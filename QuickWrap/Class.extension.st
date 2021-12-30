Extension { #name : #Class }

{ #category : #'*QuickWrap' }
Class >> addClassSlotInOrder: aSlot [

	^ self classInstaller update: self to: [ :builder | 
		  builder
			  fillFor: self;
			  classSlots:
				  ((self class classLayout slots copyWith: aSlot) sorted: [ :a :b | 
						   a name < b name ]) ]
]

{ #category : #'*QuickWrap' }
Class >> addSlotInOrder: aSlot [

	^ self classInstaller update: self to: [ :builder | 
		  builder
			  fillFor: self;
			  slots:
				  ((self localSlots copyWith: aSlot) sorted: [ :a :b | 
						   a name < b name ]) ]
]

{ #category : #'*QuickWrap' }
Class >> sortSlots [

	^ self classInstaller update: self to: [ :builder | 
		  builder
			  fillFor: self;
			  slots:
				  (self classLayout slots sorted: [ :a :b | a name < b name ]) ]
]
