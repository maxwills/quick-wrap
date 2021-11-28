Class {
	#name : #SubCacheDelegatedInstantiation,
	#superclass : #QwPostCompilationHandler,
	#category : #'QuickWrap-Core'
}

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> handleCompiledMethod: aMethod [

	"This is called by the quickWrap system if the method pragmas contains the handledPrama of this class"

	"This installs the instantiation methods proxies, which are delegated to the SubCached class. The methods will keep the same name."

	| proxy subCacheClass |
	subCacheClass := self subCacheClassFor:
		                 aMethod methodClass soleInstance.
	subCacheClass ifNil: [ 
		^ self error: 'A SubCache is required to install delegation proxies' ].
	"Copy the method to the deletage"
	subCacheClass class compileSecretly: (aMethod sourceCode
			 copyReplaceAll: self handledPragma
			 with: 'delegateMethodProxyTarget'). "prevent recursion"
	"Install the delegation proxy. This will make the base class to execute the subclass' method instead (Ignoring its own method)"
	proxy := QuickWrapMethodProxyForDelegation
		         onMethod: aMethod
		         delegateHandler: subCacheClass
		         selector: aMethod selector.
	proxy install
]

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> handledPragma [

	^ #subCacheDelegated
]

{ #category : #'as yet unclassified' }
SubCacheDelegatedInstantiation class >> subCacheClassFor: aClass [

	aClass subclasses do: [ :s | 
		(SubCache classIsSubCache: s) ifTrue: [ ^ s ] ].
	^ nil
]
