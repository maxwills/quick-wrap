"
A quickwarp to redirect a method. There is no ""wrapping"" at all. The proxified method is not executed. only the proxy's
"
Class {
	#name : #QuickWrapMethodProxyForDelegation,
	#superclass : #QuickWrapMethodProxy,
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
