"
Same as QwMethodProxy, but with exception handling. Therefore, it is slower, but more appropriate for wrapping critical methods.
"
Class {
	#name : #QuickWrapSafeMethodProxy,
	#superclass : #QuickWrapMethodProxy,
	#pools : [
		'MpMethodProxyPool'
	],
	#category : #'QuickWrap-Proxy'
}

{ #category : #evaluation }
QuickWrapSafeMethodProxy >> run: aSelector with: anArrayOfObjects in: aReceiver [

	"Do not intercept"

	<methodProxyCannotWrap>
	| returnValue |
	(isDisabled or: [ "Check explicitly that the flag has been set.
		This allows proxies to work independently of initialization side effects." 
		 IsActiveInExecutionStack == true ]) ifTrue: [ 
		^ self trySafely: [ 
			  delegateReceiver value
				  perform: handlerSelector
				  withArguments: { 
						  aReceiver.
						  proxifiedMethod.
						  anArrayOfObjects } ] ].

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

{ #category : #'as yet unclassified' }
QuickWrapSafeMethodProxy >> trySafely: aBlock [

	| res shouldDisableProxy |
	shouldDisableProxy := false.
	res := aBlock
		       on: MessageNotUnderstood
		       do: [ :e | 
			       | sContext |
			       sContext := e signalContext.
			       (sContext methodClass == self class and: [ 
				        sContext selector == #valueWithReceiver:arguments: ]) 
				       ifTrue: [ "Disble the proxy in the case where calling the unproxified method fails (for example, when the unproxified method is deleted, but somehow the proxi still remains to be executed." 
					       shouldDisableProxy := true ].
			       shouldDisableProxy ifTrue: [ 
				       self inform: 'ERROR IN PROXY FOR ' , selector asString
					       ,
					       '. Disabling the proxy. It can be re-enabled by recompiling the method with the pragma'.
				       self qwDisableProxy ].
			       e signalIn: e signalContext ].
	^ res
]

{ #category : #evaluating }
QuickWrapSafeMethodProxy >> valueWithReceiver: receiver arguments: arguments [

	<methodProxyCannotWrap>
	| result |
	"Purposely do not use a non-local return.
	Otherwise the non-local return logic would be instrumented and this could end in infinite loops"
	[ 
	IsActiveInExecutionStack := false.
	result := self trySafely: [ 
		          delegateReceiver value
			          perform: handlerSelector
			          withArguments: { 
					          receiver.
					          proxifiedMethod.
					          arguments } ].
	"the following code should be executed by the wrapper"
	"MwMethodProxy receiver: receiver withArgs: arguments executeMethod: wrappedMethod."

	"Eagerly set it to true to avoid instrumenting all messages done during the ensure"
	IsActiveInExecutionStack := true ] methodProxyEnsure: activator.
	^ result
]
