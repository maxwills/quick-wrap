"
## QuickWrap
QuickWrap system adds a set of post method compilation functions. This functions are hooked by adding any of the following wrapping pragmas to your methods.

<quickWrapWith: #yourWrapperMethodSelector>
<subCached>
(<autoCache> is now deprecated)

## Usage
To use QuickWrap system, the installQuickWrapSystem method must be executed.
QuickWrap installQuickWrapSystem
Depending on the baseline installed, this step is performed automatically or you might need to do it manually.
This will modify Behavior >> addSelectorSilently:withMethod: to add a post compilation hook.
For explanations on how to use each proxy, see each class comments.!
!QuickWrap commentStamp: 'Max 11/28/2021 10:57' prior: 34387187!
## QuickWrap
QuickWrap system adds a set of post method compilation functions. This functions are hooked by adding any of the following wrapping pragmas to your methods.

<quickWrapWith: #yourWrapperMethodSelector>
<subCached>
(<autoCache> is now deprecated)

## Usage
To use QuickWrap system, the installQuickWrapSystem method must be executed.
QuickWrap installQuickWrapSystem
Depending on the baseline installed, this step is performed automatically or you might need to do it manually.
This will modify Behavior >> addSelectorSilently:withMethod: to add a post compilation hook.
For explanations on how to use each proxy, see each class comments.

## What is in this class?

The class side contains all the methods that the system uses.
In instance side contains method templates. They are not used directly, but instead, their source code is used to compile other methods necessary to the system.

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


	methodClass := method methodClass.

	"Installing a MwMethodProxy"

	proxy := AutoCacheMethodProxy onMethod: method.
	proxy install
]

{ #category : #'as yet unclassified' }
QuickWrap class >> doQuickWrapWithCompileHandler: method [

	"Called when a method is compiled, right after adding it to the method dictionary of the class"

	| pragma selector methodClass proxy |
	pragma := method pragmaAt: #quickWrapWith:.
	pragma ifNil: [ ^ method ].
	selector := method selector.


	methodClass := method methodClass.

	"Installing a MwMethodProxy"

	proxy := QuickWrapMethodProxy
		         onMethod: method
		         handlerSelector: pragma arguments first.
	proxy install.
	^ method
]

{ #category : #'as yet unclassified' }
QuickWrap class >> executeMethodCompiledHandlersFor: method [

	"Called when a method is compiled, right after adding it to the method dictionary of the class"

	(self currentlyWrapping anySatisfy: [ :each | 
		 each methodClass == method methodClass and: [ 
			 each selector == method selector ] ]) ifTrue: [ ^ method ].
	[ 
	self currentlyWrapping add: method.
	self doQuickWrapWithCompileHandler: method.
	self doAutoCacheCompileHandler: method.
	QwPostCompilationHandler subclassesDo: [ :s | 
		(s methodHasPragma: method) ifTrue: [ 
			s handleCompiledMethod: method ] ] ] ensure: [ 
		self currentlyWrapping remove: method ]
]

{ #category : #'as yet unclassified' }
QuickWrap class >> installQuickWrapSystem [

	"Install a post method installation hook, which enables QuickWrap features"

	"This means that only installed methods (ie, methods that are added to a class' methodDictionary (The class itself doesn't need to be installed)) can be wrapped by using any of the wrapping pragmas"

	| originalMethod originalCompileSource |
	#Uninstall_it_first.
	self uninstallQuickWrapSystem.
	#Install_it_now. 
	originalMethod := Behavior methodDictionary at:
		                  #addSelectorSilently:withMethod:.
	originalCompileSource := 'original_' , originalMethod sourceCode trim.
	Behavior compile: originalCompileSource.
	Behavior compile:
		(self methodDictionary at: #addSelectorSilently:withMethod:)
			sourceCode.
	#Its_installed_now
]

{ #category : #enumerating }
QuickWrap class >> secretlyDo: aBlock [

	"Suspends announcers while performing the block"

	SystemAnnouncer uniqueInstance suspendAllWhile: aBlock
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
