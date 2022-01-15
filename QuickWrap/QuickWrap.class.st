"
## QuickWrap
QuickWrap system adds a set of post method compilation functions. This functions are hooked by adding any of the following wrapping pragmas to your methods.

0: IMPORTANT!!!!!!!!!!
Install by executing: QuickWrap installQuickWrapSystem ""enables the compilation hook"".
Then, activate the existing pragmas by executing: QuickWrap refreshAllWrappers ""activates existing pragmas"".
(Without last line, already existing pragmas remain inactive unless the methods are recompiled)

1. <quickWrapWith: #yourWrapperMethod:wrappedMethod:arguments:> 

In the same object, then define

yourWrapperMethod: receiver wrappedMethod: aMethod arguments: args
	""receiver object, aMethod is the wrapped method, args is the list of arguments of the original call""
	""IN THIS WRAPPER, YOU MUST CALL THE WRAPPED METHOD YOURSELF (if you intend so)""
	| res |
	""process the arguments here""
	res := receiver execute: aMethod withArgs: args.
	""process the result here""
	^ 'result is new: ' , res asString

2. <#quickWrappedBy: #AClass selector: #yourWrapperMethod:wrappedMethod:arguments:> 

""Same as previous example, but the wrapper method can be defined in any class""

3. <subCached>

""Auto cache method results. Used when in need for performance. You need to be sure that using
this cache mechanism is faster than computing a method return.
It doesn't uses proxies, instead, it automatically generates a subclass that caches its super class method return values. The cached values lifetime is controlable""

## Usage
To use QuickWrap system, the installQuickWrapSystem method must be executed.
QuickWrap installQuickWrapSystem

Depending on the baseline installed, this step is performed automatically or you might need to do it manually.

This will modify Behavior >> addSelectorSilently:withMethod: to add a post compilation hook.
For explanations on how to use each proxy, see each class comments.!

Uninstall the hooks and proxies by calling QuickWrap uninstallQuickWrapSystem. Pragmas will remain, and also the generated code, although they will become inactive, as expected.

To enable the System, first execute QuickWrap installQuickWrapSystem to enable the compilation hooks. Then execute QuickWrap refreshAllWrappers to activate the pragmas.

"
Class {
	#name : #QuickWrap,
	#superclass : #Object,
	#classVars : [
		'forceDisableLogging'
	],
	#classInstVars : [
		'currentlyWrapping'
	],
	#category : #'QuickWrap-Core'
}

{ #category : #testing }
QuickWrap class >> acceptsLoggingOfCompilationWrapper: receiver method: method args: args [

	^ forceDisableLogging not and: [ 
		  receiver withArgs: args executeMethod: method ]
]

{ #category : #accessing }
QuickWrap class >> currentlyWrapping [

	"A collection used to prevent recursive instrumentation"

	^ currentlyWrapping ifNil: [ 
		  currentlyWrapping := OrderedCollection new ]
]

{ #category : #testing }
QuickWrap class >> disableCompilationLoggingDuring: aBlock [

	| forceFlag |
	forceFlag := forceDisableLogging.
	forceDisableLogging := true.
	EpMonitor disableDuring: [ 
		aBlock ensure: [ forceDisableLogging := forceFlag ] ]
]

{ #category : #'as yet unclassified' }
QuickWrap class >> executeMethodCompiledHandlersFor: method [

	"Called when a method is compiled, right after adding it to the method dictionary of the class"

	(method unproxifiedMethod methodClass = self or: [ 
		 method unproxifiedMethod methodClass = self class ]) ifTrue: [ 
		^ self "prevent handling compilation of this class method as a safety measure" ].

	(self currentlyWrapping anySatisfy: [ :each | 
		 each methodClass == method methodClass and: [ 
			 each selector == method selector ] ]) ifTrue: [ ^ method ].
	[ 
	self currentlyWrapping add: method.
	QwPostCompilationHandler subclassesDo: [ :s | 
		(s methodHasPragma: method) ifTrue: [ 
			[ s handleCompiledMethod: method ] onErrorDo: [ :e | 
				self inform:
					'QuickWrap PostCompilationHandler for ' , method asString
					, ' failed. ' , e asString ] ] ] ] ensure: [ 
		self currentlyWrapping remove: method ]
]

{ #category : #testing }
QuickWrap class >> initialize [

	forceDisableLogging := false
]

{ #category : #'as yet unclassified' }
QuickWrap class >> installQuickWrapSystem [

	"Install a post method installation hook, which enables QuickWrap features"

	"This means that only installed methods (ie, methods that are added to a class' methodDictionary (The class itself doesn't need to be installed)) can be wrapped by using any of the wrapping pragmas"

	<script>
	| originalMethod originalCompileSource |
	#Uninstall_it_first.
	self uninstallQuickWrapSystem.
	#Install_it_now.
	ClassDescription compile: 'acceptsLoggingOfCompilation
	<quickWrappedBy: #QuickWrap selector:
	#acceptsLoggingOfCompilationWrapper:method:args:>
	^ true'.
	originalMethod := Behavior methodDictionary at:
		                  #addSelectorSilently:withMethod:.
	originalCompileSource := 'original_' , originalMethod sourceCode trim.
	Behavior compile: originalCompileSource.
	Behavior compile:
		(self methodDictionary at: #addSelectorSilently:withMethod:)
			sourceCode.
	#Its_installed_now.
	#additionally_install_patches.
	self patchIceRepository.
	self patchContext.
	self patchClyOldMessageBrowserAdapter.
	self patchDebugContext
]

{ #category : #'as yet unclassified' }
QuickWrap class >> patchClyOldMessageBrowserAdapter [

	"Fixes a bug related to browsing implementors that filtered out proxified methods"
 
	ClyOldMessageBrowserAdapter compile: 'messages: anObject

	messages := anObject collect: [ :m | 
		            (m respondsTo: #unproxifiedMethod)
			            ifTrue: [ m unproxifiedMethod ]
			            ifFalse: [ m ] ]'
]

{ #category : #'as yet unclassified' }
QuickWrap class >> patchContext [

	"Fixes an error that occurs when saving changes in a method when the debugger is currently executing its proxy."

	| method source |
	method := Context >> #quickWrapPrivRefreshWith:.
	method ifNil: [ ^ self "we are in trouble" ].
	source := method sourceCode
		          copyReplaceAll: 'quickWrapPrivRefreshWith:'
		          with: 'privRefreshWith:'.

	Context compile: source
]

{ #category : #'as yet unclassified' }
QuickWrap class >> patchDebugContext [

	"Fixes an error that occurs when saving changes in a method when the debugger is currently executing its proxy.
	(The unpatched case needs to save twice to display the changed method). It seems that it tries to refresh with the newMethod source code, but somehow this new method points to the old proxy, and therefore, the sourcecode display is the proxified one.
	Now it is refreshed correctly.
	"

	| method source |
	method := DebugContext >> #quickWrapRecompileCurrentMethodTo:notifying:.
	method ifNil: [ ^ self "we are in trouble" ].
	source := method sourceCode
		          copyReplaceAll: 'quickWrapRecompileCurrentMethodTo:'
		          with: 'recompileCurrentMethodTo:'.

	DebugContext compile: source
]

{ #category : #'as yet unclassified' }
QuickWrap class >> patchIceRepository [

	"Fixes a bug related to browsing a method that was compiled secretly"

	| method originalSourceCode newSourceCode |
	method := IceRepository class>> #registeredRepositoryIncludingPackage:.
	method ifNil: [ ^ self "we are in trouble" ].
	originalSourceCode := method sourceCode.

	newSourceCode := originalSourceCode
		                 copyReplaceAll: 'aPackage ifNil: [ ^ nil ].
'
		                 with: ''.
	newSourceCode := newSourceCode
		                 copyReplaceAll: '^ self registry'
		                 with: 'aPackage ifNil: [ ^ nil ].
	^ self registry'.
	IceRepository class compile: newSourceCode

	"Should look something like this:"
	"registeredRepositoryIncludingPackage: aPackage

	aPackage ifNil: [ ^ nil ].
	^ self registry
		  detect: [ :each | each includesPackageNamed: aPackage name ]
		  ifNone: [ nil ]"
]

{ #category : #'as yet unclassified' }
QuickWrap class >> refreshAllWrappers [

	<script>
	QwPostCompilationHandler refreshAllProxies
]

{ #category : #enumerating }
QuickWrap class >> secretlyDo: aBlock [

	"Suspends announcers while performing the block"

	SystemAnnouncer uniqueInstance suspendAllWhile: aBlock
]

{ #category : #'as yet unclassified' }
QuickWrap class >> uninstallQuickWrapSystem [

	<script>
	| originalMethod originalCompileSource |
	self flag: 'First remove the Compilation hook'.
	(Behavior methodDictionary includesKey:
		 #original_addSelectorSilently:withMethod:) ifTrue: [ 
		originalMethod := Behavior methodDictionary at:
			                  #original_addSelectorSilently:withMethod:.
		originalCompileSource := originalMethod sourceCode trim 
			                         withoutPrefix: #original_.
		Behavior compile: originalCompileSource.
		Behavior removeSelectorSilently:
			#original_addSelectorSilently:withMethod: ].


	self flag: 'Secondily, recompile all the original methods'.
	QwPostCompilationHandler refreshAllProxies
]

{ #category : #'as yet unclassified' }
QuickWrap >> addSelectorSilently: selector withMethod: method [

	"Method compilation interceptor installed by QuickWrap. Use QuickWrap uninstall to revert changes"

	| returnVal |
	returnVal := self
		             original_addSelectorSilently: selector
		             withMethod: method.
	^ [ 
	  self class environment
		  at: #QuickWrap
		  ifPresent: [ :qwCls | 
		  qwCls executeMethodCompiledHandlersFor: method ]
		  ifAbsent: [ returnVal ] ]
		  onErrorDo: [ :e | 
			  "| errMsg |
			  e message selector = #executeMethodCompiledHandlersFor:
				  ifTrue: [ 
					  errMsg := 'QuickWrap: Unable to process method. Missing QuickWrap class >> #executeMethodCompiledHandlersFor:' ]
				  ifFalse: [ 
					  errMsg := 'QuickWrap: Unable to process method. Missing QuickWrap class >> #executeMethodCompiledHandlersFor:' ]."
			  self inform: e asString.
			  Transcript show: e asString.
			  returnVal ]
]
