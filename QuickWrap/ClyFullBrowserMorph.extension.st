Extension { #name : #ClyFullBrowserMorph }

{ #category : #'*QuickWrap' }
ClyFullBrowserMorph class >> new [

	"QuickWrap example. Extension method"

	"If QuickWrap is active, the following code will be executed as if it was called in the subclass. If not active, it will be executed normally. "

	<qwpWrappedBy: #ClyFullBrowserMorphQwDelegate selector:
	#handleSuperNew:wrappedMethod:arguments:>

	^ super new
]
