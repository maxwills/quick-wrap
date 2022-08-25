Class {
	#name : #QWWrappersExamples,
	#superclass : #Object,
	#category : #QuickWrap
}

{ #category : #'as yet unclassified' }
QWWrappersExamples class >> incrementerWrapper1: receiver wrappedMethod: method arguments: args [

	"Does stuff before calling the wrapped method. Assumes one arg"

	| res |
	"Do stuff"
	Transcript show: 'Doing something before wrapped method ', args first asString; cr.
	"execute the wrapped method"
	res := receiver execute: method withArgs: args. 
	^ res
]

{ #category : #'as yet unclassified' }
QWWrappersExamples class >> incrementerWrapper2: receiver wrappedMethod: method arguments: args [

   "Does stuff after calling the wrapped method. Assumes one arg"
	
	|res|
	"execute the wrapped method"
	res:= receiver execute: method withArgs: args.
	"Do stuff"
	Transcript show: args first asString, ' Doing something after wrapped method '; cr.
	^res
   
]

{ #category : #'as yet unclassified' }
QWWrappersExamples class >> parenthesesWrapper: receiver wrappedMethod: method arguments: args [

	"The wrapped method must be called explicitly"

	| res |
	res := receiver execute: method withArgs: args.

	^ '(' , res , ')'
]
