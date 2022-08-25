Class {
	#name : #MyRepeater,
	#superclass : #Object,
	#category : #QuickWrap
}

{ #category : #logging }
MyRepeater class >> repeat: anObject [

	"<qwpWrappedBy: #QWWrappersExamples selector: #incrementerWrapper1:wrappedMethod:arguments:>"
	"<qwpWrappedBy: #QWWrappersExamples selector: #incrementerWrapper2:wrappedMethod:arguments:>"
	"<qwpWrappedBy: #QWWrappersExamples selector: #parenthesesWrapper:wrappedMethod:arguments:>"
	
	^  anObject
]
