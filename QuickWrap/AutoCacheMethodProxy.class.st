"
AutoCache requires that the class that uses this pragma to implement the method autoCacheTimeKey.

Just add the pragma 	<autoCache> to a method to make it autoCached.
"
Class {
	#name : #AutoCacheMethodProxy,
	#superclass : #Object,
	#instVars : [
		'selector',
		'methodClass',
		'isDisabled',
		'proxifiedMethod',
		'activator',
		'deactivator',
		'cachedTimeKey',
		'cachedValue'
	],
	#pools : [
		'MpMethodProxyPool'
	],
	#category : #'QuickWrap-Proxy'
}

{ #category : #'as yet unclassified' }
AutoCacheMethodProxy class >> onMethod: aMethod [

	| proxy |
	proxy := self new.
	proxy class: aMethod methodClass selector: aMethod selector.
	^ proxy
]

{ #category : #private }
AutoCacheMethodProxy class >> uninstallAllWrappers [
	"self uninstallAllWrappers"

	self allSubInstancesDo: [ :inst | inst uninstall ]
]

{ #category : #accessing }
AutoCacheMethodProxy >> cachedTimeKey [

	^ cachedTimeKey
]

{ #category : #accessing }
AutoCacheMethodProxy >> cachedTimeKey: anObject [

	cachedTimeKey := anObject
]

{ #category : #accessing }
AutoCacheMethodProxy >> cachedValue [

	^ cachedValue
]

{ #category : #accessing }
AutoCacheMethodProxy >> cachedValue: anObject [

	cachedValue := anObject
]

{ #category : #accessing }
AutoCacheMethodProxy >> calypsoEnvironmentType [
"Saving code changes trigger an event that calls this method. If not overridden, it will execute Object >> calypsoEnvironmentType which is not what is needed. MpMethodProxy didn't face this problem, because the installation workflow is different"
	^ proxifiedMethod calypsoEnvironmentType
]

{ #category : #initialization }
AutoCacheMethodProxy >> class: aClass selector: aSymbol [

	self
		methodClass: aClass;
		selector: aSymbol
]

{ #category : #accessing }
AutoCacheMethodProxy >> disable [

	isDisabled := true
]

{ #category : #accessing }
AutoCacheMethodProxy >> doesNotUnderstand: aMessage [
	^ proxifiedMethod 
			ifNotNil: [ proxifiedMethod 
								perform: aMessage selector 
								withArguments: aMessage arguments ]
			ifNil: [ super doesNotUnderstand: aMessage ]
			
]

{ #category : #accessing }
AutoCacheMethodProxy >> fetchMethod [
	
	"Fetches the method to be instrumented"
	^ methodClass >> selector
]

{ #category : #installation }
AutoCacheMethodProxy >> initialize [

	super initialize.
	isDisabled := true.
	activator := MpMethodProxyActivator new
]

{ #category : #installation }
AutoCacheMethodProxy >> install [
	"We have a method proxy with a method = class * selector of the method it will proxy."
	
	|  method |
	method := methodClass compiledMethodAt: selector ifAbsent: [ 
		MpCannotInstall signalWith: self ].
	
	(self shouldWrap: method) ifFalse: [ 
		MpCannotInstall signalWith: self ].
	
	self unproxifiedMethod: method.
	methodClass methodDict at: selector put: self.
	
	"Activate it now"
	isDisabled := false.
	^ self
]

{ #category : #accessing }
AutoCacheMethodProxy >> isEnabled [

	^ isDisabled not
]

{ #category : #accessing }
AutoCacheMethodProxy >> isEnabled: anObject [

	isDisabled := anObject not
]

{ #category : #testing }
AutoCacheMethodProxy >> isInstalled [
	"Return whether the receiver is effectively installed in a method dictionary.
	Note that in the case of nesting of method proxies the inner ones are not considered as installed."
	
	methodClass ifNotNil: [
		selector ifNotNil: [ 
			^ self == (methodClass methodDict at: selector ifAbsent: [])]].
	^ false
]

{ #category : #testing }
AutoCacheMethodProxy >> isMethodProxy [

	^ true
]

{ #category : #accessing }
AutoCacheMethodProxy >> methodClass [
	^ methodClass
]

{ #category : #accessing }
AutoCacheMethodProxy >> methodClass: aClass [

	methodClass := aClass
]

{ #category : #evaluating }
AutoCacheMethodProxy >> name [

	^ self printString
]

{ #category : #printing }
AutoCacheMethodProxy >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPutAll: '[';
		nextPutAll: methodClass name;
		nextPutAll: '>>#';
		nextPutAll: selector;
		nextPutAll: ']'
]

{ #category : #evaluating }
AutoCacheMethodProxy >> run: aSelector with: anArrayOfObjects in: aReceiver [

	"Do not intercept"

	<methodProxyCannotWrap>
	| returnValue |
	(isDisabled or: [ "Check explicitly that the flag has been set.
		This allows proxies to work independently of initialization side effects." 
		 IsActiveInExecutionStack == true ]) ifTrue: [ 
		| timeKey |
		timeKey := aReceiver autoCacheTimeKey.
		^ cachedTimeKey == timeKey
			  ifTrue: [ cachedValue ]
			  ifFalse: [ 
				  cachedTimeKey := timeKey.
				  cachedValue := aReceiver
					                 withArgs: anArrayOfObjects
					                 executeMethod: proxifiedMethod ] ].

	"We are now in the instrumentation world.
	Do not instrument the instrumentation."
	IsActiveInExecutionStack := true.

	"Purposely do not use a non-local return.
	Otherwise the non-local return logic would be instrumented once the ensure block is executed.
	However, since a lot of code executes between the ensure block and the real method return, this could end in infinite loops"
	[ 
	returnValue := self
		               valueWithReceiver: aReceiver
		               arguments: anArrayOfObjects ] ensure: deactivator.
	^ returnValue
]

{ #category : #accessing }
AutoCacheMethodProxy >> selector [

	^ selector
]

{ #category : #accessing }
AutoCacheMethodProxy >> selector: aSymbol [

	selector := aSymbol
]

{ #category : #installation }
AutoCacheMethodProxy >> shouldWrap: aMethod [

	(aMethod isCompiledMethod not and: [ 
		 (aMethod methodClass == self methodClass and: [ 
			  aMethod selector == self handlerSelector ]) not ]) ifTrue: [ 
		^ true ].

	aMethod isCompiledMethod ifFalse: [ ^ false ].

	^ aMethod pragmas noneSatisfy: [ :pragma | 
		  pragma selector = #methodProxyCannotWrap ]
]

{ #category : #installation }
AutoCacheMethodProxy >> uninstall [
	
	| installedMethod |
	IsActiveInExecutionStack := true.
	installedMethod := methodClass compiledMethodAt: selector ifAbsent: [ 
		IsActiveInExecutionStack := false.
		^ self ].
	installedMethod == self
		ifTrue: [ methodClass methodDict at: selector put: installedMethod wrappedMethod ].

	self unproxifiedMethod: nil.
	IsActiveInExecutionStack := false
]

{ #category : #accessing }
AutoCacheMethodProxy >> unproxifiedMethod [
	"The unproxifedMethod returns the proxified method even in case we have multiple proxified nesting."
	
	^ proxifiedMethod ifNotNil: [ proxifiedMethod unproxifiedMethod ]
]

{ #category : #'when installed' }
AutoCacheMethodProxy >> unproxifiedMethod: aCompiledMethod [

	proxifiedMethod := aCompiledMethod
]

{ #category : #evaluating }
AutoCacheMethodProxy >> valueWithReceiver: receiver arguments: arguments [

	<methodProxyCannotWrap>
	| result |
	"Purposely do not use a non-local return.
	Otherwise the non-local return logic would be instrumented and this could end in infinite loops"
	[ 
	| timeKey |
	timeKey := receiver autoCacheTimeKey.
	IsActiveInExecutionStack := false.
	result := cachedTimeKey == timeKey
		          ifTrue: [ cachedValue ]
		          ifFalse: [ 
			          cachedTimeKey := timeKey.
			          cachedValue := receiver
				                         withArgs: arguments
				                         executeMethod: proxifiedMethod ].

	"Eagerly set it to true to avoid instrumenting all messages done during the ensure"
	IsActiveInExecutionStack := true ] methodProxyEnsure: activator.
	^ result
]

{ #category : #accessing }
AutoCacheMethodProxy >> wrappedClass [

	^ methodClass
]

{ #category : #accessing }
AutoCacheMethodProxy >> wrappedClass: aClass [

	methodClass := aClass
]

{ #category : #'when installed' }
AutoCacheMethodProxy >> wrappedMethod [

	^ proxifiedMethod
]
