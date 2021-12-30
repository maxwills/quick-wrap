Class {
	#name : #QwPostCompilationHandler,
	#superclass : #Object,
	#category : #'QuickWrap-Core'
}

{ #category : #private }
QwPostCompilationHandler class >> allPragmas [

	<script>
	^ Pragma allNamed: self handledPragma
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> allowUninstall [

	^ true
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the prama of this class"

	^ self "Dont use self subclassResponsibility. See handledPragma comment"
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> handledPragma [
"<quickWrapAddPragmaToAutocompletion> subclasses should use this pragma"
	^ #unknownPragma "Dont use self subclassResponsibility here. Doing so could break the image: when installing new subclases of this one, the compilation hook would be executed and the subclassResponsibility method would throw an exception (So you won't be able to compile anything). And it is difficult to fix that without recompiling"
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> methodHasPragma: method [

	^ method pragmas anySatisfy: [ :p | p selector == self handledPragma ]
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> refreshAllProxies [

	EpMonitor disableDuring: [ self subclassesDo: [ :s | s refreshProxiesIfAllowed ] ]
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> refreshProxies [

	| pragmas toRecompile |
	toRecompile := OrderedCollection new.
	pragmas := (Pragma allNamed: self handledPragma) select: [ :p | 
		           p method unproxifiedMethod methodClass isObsolete not ].
	pragmas do: [ :p | 
		toRecompile add: { 
				p method unproxifiedMethod methodClass.
				p method unproxifiedMethod selector } ].
	EpMonitor disableDuring: [ 
		toRecompile do: [ :each | 
			| mClass mSelector method |
			mClass := each at: 1.
			mSelector := each at: 2.

			method := mClass methodDictionary at: mSelector ifAbsent: [ nil ].
			method ifNotNil: [ method unproxifiedMethod recompile ] ] ]
]

{ #category : #'as yet unclassified' }
QwPostCompilationHandler class >> refreshProxiesIfAllowed [

	self allowUninstall ifTrue: [ self refreshProxies ]
]
