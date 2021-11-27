"
To use QuickWrap system, the installQuickWrapSystem method must be executed.
This will modify Behavior >> addSelectorSilently:withMethod: to add a post compilation hook.
For explanations on how to use each proxy, see each class comments.
"
Class {
	#name : #QuickWrap,
	#superclass : #Object,
	#classInstVars : [
		'currentlyWrapping'
	],
	#category : #'QuickWrap-Core'
}

{ #category : #accessing }
QuickWrap class >> currentlyWrapping [

	"A collection used to prevent recursive instrumentation"

	^ currentlyWrapping ifNil: [ 
		  currentlyWrapping := OrderedCollection new ]
]

{ #category : #'as yet unclassified' }
QuickWrap class >> doAutoCacheCompileHandler: method [

	"Called when a method is compiled, right after adding it to the method dictionary of the class"

	| pragma selector methodClass proxy |
	pragma := method pragmaAt: #autoCache.
	pragma ifNil: [ ^ method ].
	selector := method selector.
	"preventing infinite loops"
	(self currentlyWrapping anySatisfy: [ :each | 
		 each methodClass == method methodClass and: [ 
			 each selector == selector ] ]) ifTrue: [ ^ method ].
	[ 
	self currentlyWrapping add: method.

	methodClass := method methodClass.

	"Installing a MwMethodProxy"

	proxy := AutoCacheMethodProxy onMethod: method.
	proxy install ] ensure: [ self currentlyWrapping remove: method ]
]

{ #category : #'as yet unclassified' }
QuickWrap class >> doQuickWrapWithCompileHandler: method [

	"Called when a method is compiled, right after adding it to the method dictionary of the class"

	| pragma selector methodClass proxy |
	pragma := method pragmaAt: #quickWrapWith:.
	pragma ifNil: [ ^ method ].
	selector := method selector.
	"preventing infinite loops"
	(self currentlyWrapping anySatisfy: [ :each | 
		 each methodClass == method methodClass and: [ 
			 each selector == selector ] ]) ifTrue: [ ^ method ].
	[ 
	self currentlyWrapping add: method.

	methodClass := method methodClass.

	"Installing a MwMethodProxy"

	proxy := QuickWrapMethodProxy
		         onMethod: method
		         handlerSelector: pragma arguments first.
	proxy install ] ensure: [ self currentlyWrapping remove: method ].
	^ method
]

{ #category : #'as yet unclassified' }
QuickWrap class >> doSuperCacheCompileHandler: method [

	"Called when a method is compiled, right after adding it to the method dictionary of the class"

	| pragma selector |
	Transcript show: 'Generating superCache for: ' , method selector.
	pragma := method pragmaAt: #superCached.
	pragma ifNil: [ ^ method ].
	selector := method selector.

	"preventing infinite loops"
	(self currentlyWrapping anySatisfy: [ :each | 
		 each methodClass == method methodClass and: [ 
			 each selector == selector ] ]) ifTrue: [ ^ method ].
	[ 
	self currentlyWrapping add: method.

	SuperCache generateSuperCacheFor: method ] ensure: [ 
		self currentlyWrapping remove: method ]
]

{ #category : #'as yet unclassified' }
QuickWrap class >> executeMethodCompiledHandlersFor: method [

	"Called when a method is compiled, right after adding it to the method dictionary of the class"

	self doQuickWrapWithCompileHandler: method.
	self doAutoCacheCompileHandler: method.
	self doSuperCacheCompileHandler: method
]

{ #category : #'as yet unclassified' }
QuickWrap class >> installQuickWrapSystem [

	| originalMethod originalCompileSource |
	#Uninstall_it_first.
	self uninstallQuickWrapSystem.
	#Install_it_now.
	originalMethod := Behavior methodDictionary at:
		                  #addSelectorSilently:withMethod:.
	originalCompileSource := 'original_' , originalMethod sourceCode trim.
	Behavior compile: originalCompileSource.
	Behavior compile: (self methodDictionary at: #addSelectorSilently:withMethod:) sourceCode.
	#Its_installed_now
]

{ #category : #'as yet unclassified' }
QuickWrap class >> uninstallQuickWrapSystem [

	| originalMethod originalCompileSource |
	(Behavior methodDictionary includes:
		 #original_addSelectorSilently:withMethod:) ifFalse: [ ^ self ].
	originalMethod := Behavior methodDictionary at:
		                  #original_addSelectorSilently:withMethod:.
	originalCompileSource := originalMethod sourceCode trim 
		                         withoutPrefix: #original_.
	OpalCompiler compile: originalCompileSource.
	OpalCompiler removeSelectorSilently:
		#original_addSelectorSilently:withMethod:
]

{ #category : #'as yet unclassified' }
QuickWrap >> addSelectorSilently: selector withMethod: method [

	"Method compilation interceptor installed by QuickWrap. Use QuickWrap uninstall to revert changes"

	| returnVal |
	returnVal := self
		             original_addSelectorSilently: selector
		             withMethod: method.
	^ QuickWrap executeMethodCompiledHandlersFor: method
]
