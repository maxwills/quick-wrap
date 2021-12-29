"
A class based in MpMethodProxy. Essentially a copy, but with modifications to make it work in a declarative workflow for method wrapping.

To use it, write your wrapper method, and then decorate your method to be wrapped, like this:

myWrapper: method arguments: args

	| transformedArg result |
	transformedArg := 'transformed:_' , args first.

	result := self
		          withArgs: { transformedArg }
		          executeMethod: method ""the call to the original method must be done explicitly"".
	
	result := method executeWithArgs: { transformedArg } onReceiver: self.
	
	^ '{' , result , '}'
	

myMethod: aString

	<quickWrapWith: #myWrapper:arguments:>
	
	^ aString , '_trail'
"
Class {
	#name : #QuickWrapMethodProxy,
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
QuickWrapMethodProxy class >> onMethod: aMethod delegateHandler: anObject selector: handlerSelector [

	| proxy |
	proxy := self new.
	proxy class: aMethod methodClass selector: aMethod selector.
	proxy handlerSelector: handlerSelector.
	proxy delegateReceiver: anObject.
	^ proxy
]

{ #category : #accessing }
QuickWrapMethodProxy >> calypsoEnvironmentType [
"Saving code changes trigger an event that calls this method. If not overridden, it will execute Object >> calypsoEnvironmentType which is not what is needed. MpMethodProxy didn't face this problem, because the proxy installation workflow is different"
	^ proxifiedMethod calypsoEnvironmentType
]

{ #category : #initialization }
QuickWrapMethodProxy >> class: aClass selector: aSymbol [

	self
		methodClass: aClass;
		selector: aSymbol
]

{ #category : #accessing }
QuickWrapMethodProxy >> delegateReceiver [

	^ delegateReceiver
]

{ #category : #accessing }
QuickWrapMethodProxy >> delegateReceiver: anObject [

	delegateReceiver := anObject
]

{ #category : #accessing }
QuickWrapMethodProxy >> disable [

	isDisabled := true
]

{ #category : #accessing }
QuickWrapMethodProxy >> doesNotUnderstand: aMessage [
	^ proxifiedMethod 
			ifNotNil: [ proxifiedMethod 
								perform: aMessage selector 
								withArguments: aMessage arguments ]
			ifNil: [ super doesNotUnderstand: aMessage ]
			
]

{ #category : #accessing }
QuickWrapMethodProxy >> fetchMethod [
	
	"Fetches the method to be instrumented"
	^ methodClass >> selector
]

{ #category : #accessing }
QuickWrapMethodProxy >> handlerSelector [

	^ handlerSelector
]

{ #category : #accessing }
QuickWrapMethodProxy >> handlerSelector: anObject [

	handlerSelector := anObject
]

{ #category : #installation }
QuickWrapMethodProxy >> initialize [

	super initialize.
	isDisabled := true.
	activator := MpMethodProxyActivator new
]

{ #category : #installation }
QuickWrapMethodProxy >> install [
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
QuickWrapMethodProxy >> isEnabled [

	^ isDisabled not
]

{ #category : #accessing }
QuickWrapMethodProxy >> isEnabled: anObject [

	isDisabled := anObject not
]

{ #category : #testing }
QuickWrapMethodProxy >> isInstalled [
	"Return whether the receiver is effectively installed in a method dictionary.
	Note that in the case of nesting of method proxies the inner ones are not considered as installed."
	
	methodClass ifNotNil: [
		selector ifNotNil: [ 
			^ self == (methodClass methodDict at: selector ifAbsent: [])]].
	^ false
]

{ #category : #testing }
QuickWrapMethodProxy >> isMethodProxy [

	^ true
]

{ #category : #accessing }
QuickWrapMethodProxy >> methodClass [
	^ methodClass
]

{ #category : #accessing }
QuickWrapMethodProxy >> methodClass: aClass [

	methodClass := aClass
]

{ #category : #evaluating }
QuickWrapMethodProxy >> name [

	^ self printString
]

{ #category : #printing }
QuickWrapMethodProxy >> printOn: aStream [

	aStream
		nextPutAll: self class name;
		nextPutAll: '[';
		nextPutAll: methodClass name;
		nextPutAll: '>>#';
		nextPutAll: selector;
		nextPutAll: ']'
]

{ #category : #installation }
QuickWrapMethodProxy >> qwDisableProxy [

	"Restores the original method, removing the proxy. Use only this if something goes wrong."

	| installedMethod |
	IsActiveInExecutionStack := true.
	installedMethod := methodClass
		                   compiledMethodAt: selector
		                   ifAbsent: [ 
			                   IsActiveInExecutionStack := false.
			                   ^ self ].
	installedMethod == self ifTrue: [ 
		methodClass methodDict
			at: selector
			put: installedMethod unproxifiedMethod ].

	self unproxifiedMethod: nil.
	IsActiveInExecutionStack := false
]

{ #category : #evaluating }
QuickWrapMethodProxy >> run: aSelector with: anArrayOfObjects in: aReceiver [

	"Do not intercept"

	<methodProxyCannotWrap>
	| returnValue |
	(isDisabled or: [ "Check explicitly that the flag has been set.
		This allows proxies to work independently of initialization side effects." 
		 IsActiveInExecutionStack == true ]) ifTrue: [ 
		^ delegateReceiver value perform: handlerSelector withArguments: { 
				  aReceiver.
				  proxifiedMethod.
				  anArrayOfObjects } ].

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
QuickWrapMethodProxy >> selector [

	^ selector
]

{ #category : #accessing }
QuickWrapMethodProxy >> selector: aSymbol [

	selector := aSymbol
]

{ #category : #installation }
QuickWrapMethodProxy >> shouldWrap: aMethod [

	(aMethod isCompiledMethod not and: [ 
		 (aMethod methodClass == self methodClass and: [ 
			  aMethod selector == self handlerSelector ]) not ]) ifTrue: [ 
		^ true ].

	aMethod isCompiledMethod ifFalse: [ ^ false ].

	^ aMethod pragmas noneSatisfy: [ :pragma | 
		  pragma selector = #methodProxyCannotWrap ]
]

{ #category : #installation }
QuickWrapMethodProxy >> uninstall [

	^ self error:
		  'do not unistall proxies directly. They are handled by the QuickWrap system and pragmas. 
	To remove the wrap, remove the pragma from the code or uninstall QuickWrap'
	"| installedMethod |
	IsActiveInExecutionStack := true.
	installedMethod := methodClass compiledMethodAt: selector ifAbsent: [ 
		IsActiveInExecutionStack := false.
		^ self ].
	installedMethod == self
		ifTrue: [ methodClass methodDict at: selector put: installedMethod wrappedMethod ].

	self unproxifiedMethod: nil.
	IsActiveInExecutionStack := false"
]

{ #category : #accessing }
QuickWrapMethodProxy >> unproxifiedMethod [
	"The unproxifedMethod returns the proxified method even in case we have multiple proxified nesting."
	
	^ proxifiedMethod ifNotNil: [ proxifiedMethod unproxifiedMethod ]
]

{ #category : #'when installed' }
QuickWrapMethodProxy >> unproxifiedMethod: aCompiledMethod [

	proxifiedMethod := aCompiledMethod
]

{ #category : #evaluating }
QuickWrapMethodProxy >> valueWithReceiver: receiver arguments: arguments [

	<methodProxyCannotWrap>
	| result |
	"Purposely do not use a non-local return.
	Otherwise the non-local return logic would be instrumented and this could end in infinite loops"
	[ 
	IsActiveInExecutionStack := false.
	result := delegateReceiver value
		          perform: handlerSelector
		          withArguments: { 
				          receiver.
				          proxifiedMethod.
				          arguments }.
	"the following code should be executed by the wrapper"
	"MwMethodProxy receiver: receiver withArgs: arguments executeMethod: wrappedMethod."

	"Eagerly set it to true to avoid instrumenting all messages done during the ensure"
	IsActiveInExecutionStack := true ] methodProxyEnsure: activator.
	^ result
]

{ #category : #accessing }
QuickWrapMethodProxy >> wrappedClass [

	^ methodClass
]

{ #category : #accessing }
QuickWrapMethodProxy >> wrappedClass: aClass [

	methodClass := aClass
]

{ #category : #'when installed' }
QuickWrapMethodProxy >> wrappedMethod [

	^ proxifiedMethod
]
