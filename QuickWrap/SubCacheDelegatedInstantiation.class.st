Class {
	#name : #SubCacheDelegatedInstantiation,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the handledPrama of this class"

	"This installs the instantiation methods proxies, which are delegated to the SubCached class. The methods will keep the same name."

	"In current version this only works for class methods"

	| proxy subCacheClass |
	(SubCache classHasSubCache: aMethod methodClass soleInstance)
		ifFalse: [ 
			subCacheClass := SubCache createSubCacheClassFor:
				                 aMethod unproxifiedMethod methodClass
					                 soleInstance.
			SubCache addSubCacheBaseSlotsAndMethods: subCacheClass ]
		ifTrue: [ 
			subCacheClass := self subCacheClassFor:
				                 aMethod unproxifiedMethod methodClass
					                 soleInstance ].
	subCacheClass ifNil: [ 
		^ self error: 'A SubCache is required to install delegation proxies' ].
	"Copy the method to the deletage"
	subCacheClass class compileSecretly:
		(aMethod unproxifiedMethod sourceCode
			 copyReplaceAll: self handledPragma
			 with: 'delegateMethodProxyTarget'). "prevent recursion"
	"Install the delegation proxy. This will make the base class to execute the subclass' method instead (Ignoring its own method)"
	proxy := QuickWrapMethodProxyForDelegation
		         onMethod: aMethod unproxifiedMethod
		         delegateHandler: subCacheClass
		         selector: aMethod selector.
	proxy install
]

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> handledPragma [

	<qwpAddPragmaToAutocompletion>
	^ #qwpSubCacheDelegated
]

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> refreshAllMethodsDelegationsForDelegates [

	"Should be called after loading packages with method delegations. Because its possible that the proxies are not installed if QuickWrap installation is executed as a post operation"

	| pragmas |
	
	pragmas := (Pragma allNamed: #delegateMethodProxyTarget) select: [ :p | 
		           p method methodClass isObsolete not and: [ 
			           p method methodClass soleInstance isSubCache ] ].
	pragmas do: [ :each | 
		| selector pClass targetMethod sourceCode |
		selector := each method selector.
		pClass := each method methodClass soleInstance superclass.
		targetMethod := (pClass class >> selector) unproxifiedMethod.
		sourceCode := targetMethod sourceCode.
		pClass class compile: sourceCode ]
]

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> refreshAllMethodsDelegationsForOriginals [

	"Should be called after loading packages with method delegations. Because its possible that the proxies are not installed if QuickWrap installation is executed as a post operation"

	| pragmas |
	pragmas := (Pragma allNamed: self handledPragma) select: [ :p | 
		           p method unproxifiedMethod methodClass isObsolete not ].
	pragmas do: [ :each | 
		| selector pClass targetMethod sourceCode |
		selector := each method selector.
		pClass := each method methodClass.
		targetMethod := (pClass >> selector) unproxifiedMethod.
		sourceCode := targetMethod sourceCode.
		EpMonitor disableDuring: [ 
			pClass compile: sourceCode "Not using compileSecretly. We want to kep the actual source code" ] ]
]

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> refreshProxies [

	"Should be called after loading packages with method delegations. Because its possible that the proxies are not installed if QuickWrap installation is executed as a post operation"

	self refreshAllMethodsDelegationsForDelegates.
	"Originals go after, to avoid doing them twice"
	self refreshAllMethodsDelegationsForOriginals
]

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> subCacheClassFor: aClass [

	aClass subclasses do: [ :s | 
		(SubCache classIsSubCache: s) ifTrue: [ ^ s ] ].
	^ nil
]
