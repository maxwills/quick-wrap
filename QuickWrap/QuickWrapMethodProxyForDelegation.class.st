Class {
	#name : #QuickWrapMethodProxyForDelegation,
	#superclass : #Object,
	#instVars : [
		'selector',
		'methodClass',
		'isDisabled',
		'delegateReceiver',
		'proxifiedMethod',
		'handlerSelector',
		'activator',
		'deactivator'
	],
	#pools : [
		'MpMethodProxyPool'
	],
	#category : #'QuickWrap-Proxy'
}

{ #category : #'as yet unclassified' }
QuickWrapMethodProxyForDelegation class >> onMethod: aMethod delegateHandler: anObject selector: handlerSelector [

	| proxy |
	proxy := self new.
	proxy class: aMethod methodClass selector: aMethod selector.
	proxy handlerSelector: handlerSelector.
	proxy delegateReceiver: anObject.
	^ proxy
]

{ #category : #private }
QuickWrapMethodProxyForDelegation class >> uninstallAllWrappers [
	"self uninstallAllWrappers"

	self allSubInstancesDo: [ :inst | inst uninstall ]
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> calypsoEnvironmentType [
"Saving code changes trigger an event that calls this method. If not overridden, it will execute Object >> calypsoEnvironmentType which is not what is needed. MpMethodProxy didn't face this problem, because the installation workflow is different"
	^ proxifiedMethod calypsoEnvironmentType
]

{ #category : #initialization }
QuickWrapMethodProxyForDelegation >> class: aClass selector: aSymbol [

	self
		methodClass: aClass;
		selector: aSymbol
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> delegateReceiver [

	^ delegateReceiver
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> delegateReceiver: anObject [

	delegateReceiver := anObject
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> disable [

	isDisabled := true
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> doesNotUnderstand: aMessage [
	^ proxifiedMethod 
			ifNotNil: [ proxifiedMethod 
								perform: aMessage selector 
								withArguments: aMessage arguments ]
			ifNil: [ super doesNotUnderstand: aMessage ]
			
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> fetchMethod [
	
	"Fetches the method to be instrumented"
	^ methodClass >> selector
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> handlerSelector [

	^ handlerSelector
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> handlerSelector: anObject [

	handlerSelector := anObject
]

{ #category : #installation }
QuickWrapMethodProxyForDelegation >> initialize [

	super initialize.
	isDisabled := true.
	activator := MpMethodProxyActivator new
]

{ #category : #installation }
QuickWrapMethodProxyForDelegation >> install [
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
QuickWrapMethodProxyForDelegation >> isEnabled [

	^ isDisabled not
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> isEnabled: anObject [

	isDisabled := anObject not
]

{ #category : #testing }
QuickWrapMethodProxyForDelegation >> isInstalled [
	"Return whether the receiver is effectively installed in a method dictionary.
	Note that in the case of nesting of method proxies the inner ones are not considered as installed."
	
	methodClass ifNotNil: [
		selector ifNotNil: [ 
			^ self == (methodClass methodDict at: selector ifAbsent: [])]].
	^ false
]

{ #category : #testing }
QuickWrapMethodProxyForDelegation >> isMethodProxy [

	^ true
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> methodClass [
	^ methodClass
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> methodClass: aClass [

	methodClass := aClass
]

{ #category : #evaluating }
QuickWrapMethodProxyForDelegation >> name [

	^ self printString
]

{ #category : #printing }
QuickWrapMethodProxyForDelegation >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPutAll: '[';
		nextPutAll: methodClass name;
		nextPutAll: '>>#';
		nextPutAll: selector;
		nextPutAll: ']'
]

{ #category : #evaluating }
QuickWrapMethodProxyForDelegation >> run: aSelector with: anArrayOfObjects in: aReceiver [

	"Do not intercept"

	<methodProxyCannotWrap>
	| returnValue |
	(isDisabled or: [ "Check explicitly that the flag has been set.
		This allows proxies to work independently of initialization side effects." 
		 IsActiveInExecutionStack == true ]) ifTrue: [ 
		^ delegateReceiver 
			  withArgs: anArrayOfObjects
			  executeMethod: proxifiedMethod ].

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
QuickWrapMethodProxyForDelegation >> selector [

	^ selector
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> selector: aSymbol [

	selector := aSymbol
]

{ #category : #installation }
QuickWrapMethodProxyForDelegation >> shouldWrap: aMethod [

	(aMethod isCompiledMethod not and: [ 
		 (aMethod methodClass == self methodClass and: [ 
			  aMethod selector == self handlerSelector ]) not ]) ifTrue: [ 
		^ true ].

	aMethod isCompiledMethod ifFalse: [ ^ false ].

	^ aMethod pragmas noneSatisfy: [ :pragma | 
		  pragma selector = #methodProxyCannotWrap ]
]

{ #category : #installation }
QuickWrapMethodProxyForDelegation >> uninstall [
	
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
QuickWrapMethodProxyForDelegation >> unproxifiedMethod [
	"The unproxifedMethod returns the proxified method even in case we have multiple proxified nesting."
	
	^ proxifiedMethod ifNotNil: [ proxifiedMethod unproxifiedMethod ]
]

{ #category : #'when installed' }
QuickWrapMethodProxyForDelegation >> unproxifiedMethod: aCompiledMethod [

	proxifiedMethod := aCompiledMethod
]

{ #category : #evaluating }
QuickWrapMethodProxyForDelegation >> valueWithReceiver: receiver arguments: arguments [

	<methodProxyCannotWrap>
	| result |
	"Purposely do not use a non-local return.
	Otherwise the non-local return logic would be instrumented and this could end in infinite loops"
	[ 
	IsActiveInExecutionStack := false.
	result := delegateReceiver
		          perform: handlerSelector
		          withArguments: arguments.
	"the following code should be executed by the wrapper"
	"MwMethodProxy receiver: receiver withArgs: arguments executeMethod: wrappedMethod."

	"Eagerly set it to true to avoid instrumenting all messages done during the ensure"
	IsActiveInExecutionStack := true ] methodProxyEnsure: activator.
	^ result
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> wrappedClass [

	^ methodClass
]

{ #category : #accessing }
QuickWrapMethodProxyForDelegation >> wrappedClass: aClass [

	methodClass := aClass
]

{ #category : #'when installed' }
QuickWrapMethodProxyForDelegation >> wrappedMethod [

	^ proxifiedMethod
]
