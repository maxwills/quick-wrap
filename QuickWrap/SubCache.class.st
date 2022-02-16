Class {
	#name : #SubCache,
	#superclass : #QwPostCompilationHandler,
	#instVars : [
		'__cached___cachedMethodTemplate',
		'__cached___cachedMethodTemplateTimeKey',
		'_cacheTimeKey'
	],
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
SubCache class >> addSubCacheBaseSlotsAndMethods: subCacheClass [

	| updateMethod |
	subCacheClass addSlotSecretlyAndInOrder: #_cacheTimeKey => InstanceVariableSlot.
	updateMethod := subCacheClass methodDictionary
		                at: #updateCacheTimeKey
		                ifAbsent: [ nil ].
	updateMethod ifNil: [ 
		"#updateCacheTime compiled not silently on purpose (so it can be modified and registered in the repository without problems"
		subCacheClass compile: 'updateCacheTimeKey
	_cacheTimeKey := yourexpression toUpdateTheTimekey"Example: myInstanceVariable  (or self aMethod)" "DONT USE CACHED METHODS of self. You can use super methods"' ].
	subCacheClass compileSecretly: 'resetCacheTimeKey
	self class slots do: [ :s | s write: nil to: self ]'.
	subCacheClass compileSecretly: 'cacheTimeKey: anObject
	_cacheTimeKey := anObject'.
	subCacheClass class compileSecretly: 'isSubCache
	^true'
]

{ #category : #'as yet unclassified' }
SubCache class >> canHaveSubCache: aClass [

	aClass subclasses ifEmpty: [ ^ true ] ifNotEmpty: [ 
		| subs |
		subs := aClass subclasses.
		subs size = 1
			ifFalse: [ 
				self inform:
					'Ensure that the class has no subclasses other than the subcache or has no subclasses at all'.
				^ false ]
			ifTrue: [ ^ self classIsSubCache: subs first ] ]
]

{ #category : #'as yet unclassified' }
SubCache class >> classHasSubCache: aClass [

	| subs |
	subs := aClass subclasses.
	subs ifNotEmpty: [ ^ self classIsSubCache: subs first ].
	^ false
]

{ #category : #'as yet unclassified' }
SubCache class >> classIsSubCache: aClass [

	^ (aClass class methodDictionary includesKey: #isSubCache "preventing lookups")
		  ifTrue: [ aClass isSubCache ]
		  ifFalse: [ false ]
]

{ #category : #'as yet unclassified' }
SubCache class >> cleanUpAllSlotsAndMethodsOf: subCacheClass [

	"This is dangerous.. beware"

	"This spares the method #updateCacheTimeKey which is supposed to be written by the developer"

	QuickWrap secretlyDo: [ 
		| slots updateMethod updateMethodSource |
		slots := subCacheClass slots shallowCopy.
		slots do: [ :s | subCacheClass removeSlot: s ].
		updateMethod := subCacheClass methodDictionary
			                at: #updateCacheTimeKey
			                ifAbsent: [ nil ].
		updateMethodSource := updateMethod ifNotNil: [ 
			                      updateMethod sourceCode ].
		subCacheClass methodDictionary removeAll.
		subCacheClass class methodDictionary removeAll.
		updateMethodSource ifNotNil: [ 
			subCacheClass compileSecretly: updateMethodSource ] ]
]

{ #category : #'as yet unclassified' }
SubCache class >> createSubCacheClassFor: aClass [

	"Creates an empty class to be used as subcache for aClass. If it already exists, it emptiesIt"

	| subCacheName subCacheClass |
	subCacheName := 'SubCached' , aClass name.
	subCacheClass := self environment at: subCacheName ifAbsent: [ nil ].
	subCacheClass ifNotNil: [ 
		self cleanUpAllSlotsAndMethodsOf: subCacheClass.
		^ subCacheClass ].

	"Dont do this secretly"
	^ ((aClass << subCacheName)
		   slots: {  };
		   package: aClass category;
		   yourself) install
]

{ #category : #'as yet unclassified' }
SubCache class >> generateSubCacheFor: aMethod [

	| subs targetClass selector templateMethod sourceCode |
	subs := aMethod methodClass subclasses.
	subs ifEmpty: [ 
		^ self inform:
			  'The cache needs to be installed in the first subclass. No subclass detected. Aborting.' ].
	targetClass := subs first.
	selector := aMethod selector.

	templateMethod := SubCache methodDictionary at:
		                  #__cachedMethodTemplate.
	sourceCode := templateMethod sourceCode trim
		              copyReplaceAll: '__cachedMethodTemplate'
		              with: selector.
	(targetClass slots anySatisfy: [ :s | 
		 s name == (#__cached_ , selector) ]) ifFalse: [ 
		targetClass addSlotSecretlyAndInOrder: 
			#__cached_ , selector => InstanceVariableSlot.
		targetClass addSlotSecretlyAndInOrder:
			#__cached_ , selector , #TimeKey => InstanceVariableSlot ].
	targetClass compileSecretly: sourceCode
]

{ #category : #'as yet unclassified' }
SubCache class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the pragma of this class"

	| selector |
	selector := aMethod selector.
	(self classHasSubCache: aMethod unproxifiedMethod methodClass) ifFalse: [ 
		| subCacheClass |
		subCacheClass := self createSubCacheClassFor: aMethod methodClass.
		self addSubCacheBaseSlotsAndMethods: subCacheClass ].

	self generateSubCacheFor: aMethod
]

{ #category : #'as yet unclassified' }
SubCache class >> handledPragma [

	<qwpAddPragmaToAutocompletion>
	^ #qwpSubCached
]

{ #category : #'as yet unclassified' }
SubCache class >> regenerateSubCacheForClass: aClass [

	| subCacheClass |
	(self canHaveSubCache: aClass) ifFalse: [ 
		^ self inform:
			  'The class can''t have subCache. Delete its subclasses.' ].
	subCacheClass := self createSubCacheClassFor: aClass.
	self addSubCacheBaseSlotsAndMethods: subCacheClass.
	(aClass methodDictionary values sorted: [:a :b| a selector < b selector]) do: [ :method | 
		(self methodHasPragma: method) ifTrue: [ 
			self generateSubCacheFor: method ] ]
]

{ #category : #'as yet unclassified' }
SubCache class >> removeAllSlotsAndMethodsOf: subCacheClass [

	"This is dangerous.. beware"

	QuickWrap secretlyDo: [ 
		| slots |
		slots := subCacheClass slots shallowCopy.
		slots do: [ :s | subCacheClass removeSlot: s ].
		subCacheClass methodDictionary removeAll.
		subCacheClass class methodDictionary removeAll ]
]

{ #category : #removing }
SubCache class >> removeSubCacheForClass: aClass [

	| subCacheClass methodsToRestore |
	self error: 'Dont call this'.
	subCacheClass := self subCacheClassFor: aClass.
	subCacheClass ifNil: [ ^ self ].
	methodsToRestore := aClass class methodDictionary values select: [ :m | 
		                    SubCacheDelegatedInstantiation methodHasPragma:
			                    m ].
	methodsToRestore do: [ :m | 
		m class == QuickWrapMethodProxyForDelegation ifTrue: [ " m uninstall""THIS BREAKS THE IMAGE"
			 ] ]
]

{ #category : #'as yet unclassified' }
SubCache >> __cachedMethodTemplate [

	"Code automatically generated by SuperCache"

	^ _cacheTimeKey == __cached___cachedMethodTemplateTimeKey
		  ifTrue: [ __cached___cachedMethodTemplate ]
		  ifFalse: [ 
			  __cached___cachedMethodTemplateTimeKey := _cacheTimeKey.
			  __cached___cachedMethodTemplate := super __cachedMethodTemplate ]
]
