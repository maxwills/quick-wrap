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
		^ [ 
		  delegateReceiver value perform: handlerSelector withArguments: { 
				  aReceiver.
				  proxifiedMethod.
				  anArrayOfObjects } ]
			  on: MessageNotUnderstood
			  do: [ :e | 
				  e message selector == #valueSafelyWithReceiver:arguments:
					  ifTrue: [ 
						  self inform:
							  'Error calling MethodProxy. ' , '()' , e asString
							  ,
							  '. Disabling the proxy. It can be re-enabled by recompiling the original method with the pragma'.
						  self qwDisableProxy ]
					  ifFalse: [ 
						self flag: 'SEEKER USERS READ THIS:
						To see details of the exception, evaluate the following line (Select and do cmd+d):
						 e debug "you can only debug it once"
						'.
						e defaultAction ] ] ].

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
QuickWrapSafeMethodProxy >> valueSafelyWithReceiver: receiver arguments: arguments [

	<methodProxyCannotWrap>
	| result |
	[ 
	result := delegateReceiver value
		          perform: handlerSelector
		          withArguments: { 
				          receiver.
				          proxifiedMethod.
				          arguments } ]
		on: MessageNotUnderstood
		do: [ :e | 
			e message selector == #valueSafelyWithReceiver:arguments:
				ifTrue: [ 
					self inform: 'Error calling MethodProxy. ' , '()' , e asString
						,
						'. Disabling the proxy. It can be re-enabled by recompiling the original method with the pragma'.
					self qwDisableProxy ]
				ifFalse: [ e defaultAction ] ].
	^ result
]

{ #category : #evaluating }
QuickWrapSafeMethodProxy >> valueWithReceiver: receiver arguments: arguments [

	<methodProxyCannotWrap>
	| result |
	"Purposely do not use a non-local return.
	Otherwise the non-local return logic would be instrumented and this could end in infinite loops"
	[ 
	IsActiveInExecutionStack := false.
	result := [ 
	          delegateReceiver value
		          perform: handlerSelector
		          withArguments: { 
				          receiver.
				          proxifiedMethod.
				          arguments } ]
		          on: MessageNotUnderstood
		          do: [ :e | 
			          e message selector == #valueSafelyWithReceiver:arguments:
				          ifTrue: [ 
					          self inform:
						          'Error calling MethodProxy. ' , '()' , e asString
						          ,
						          '. Disabling the proxy. It can be re-enabled by recompiling the original method with the pragma'.
					          self qwDisableProxy ]
				          ifFalse: [ e defaultAction ] ].
	"the following code should be executed by the wrapper"
	"MwMethodProxy receiver: receiver withArgs: arguments executeMethod: wrappedMethod."

	"Eagerly set it to true to avoid instrumenting all messages done during the ensure"
	IsActiveInExecutionStack := true ] methodProxyEnsure: activator.
	^ result
]
