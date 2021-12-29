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
