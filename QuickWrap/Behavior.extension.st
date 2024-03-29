Extension { #name : #Behavior }

{ #category : #'*QuickWrap' }
Behavior >> compileWithoutEpiceaLogging: code [

	"Compile the argument, code, as source code in the context of the 
	receiver. Create an error notification if the code can not be compiled. 
	The argument is either a string or an object that converts to a string or a 
	PositionableStream on an object that converts to a string."

	^ EpMonitor disableDuring: [ self compile: code ]
]
