"
A ""delegate"" subclass of ClyFullBrowserMorph.
When QuickWrap system is active, this class is used instead of ClyFullBrowserMorph.

Create as an example of QuickWrap usage.

It remembers the size of the windows by registering in a class variable. If a new window is created, it will have the size of the last registered size.
"
Class {
	#name : #ClyFullBrowserMorphQwDelegate,
	#superclass : #ClyFullBrowserMorph,
	#classVars : [
		'rememberedExtent'
	],
	#category : #'QuickWrap-Utils'
}

{ #category : #'as yet unclassified' }
ClyFullBrowserMorphQwDelegate class >> handleSuperNew: receiver wrappedMethod: aMethod arguments: args [

	"This method handles the execution of the superclass new method. This means that it is executed with self as a receiver and not the other class class"
   "In fact, this wrapping/handler method could be in any class, not necessarily in a subclass of the original."
	| res |
	"we change the receiver of the new message to self"
	res := self execute: aMethod withArgs: args.

	^ res
]

{ #category : #initialization }
ClyFullBrowserMorphQwDelegate class >> initialize [

	rememberedExtent := 1000 @ 620
]

{ #category : #geometry }
ClyFullBrowserMorphQwDelegate >> extent: aPoint [

	| res |
	res := super extent: aPoint.
	rememberedExtent := self extent.
	^ res
]

{ #category : #api }
ClyFullBrowserMorphQwDelegate >> initialExtent [

	^ rememberedExtent
]
