Class {
	#name : #MyRepeater,
	#superclass : #Object,
	#category : #QuickWrap
}

{ #category : #logging }
MyRepeater class >> repeat: anObject [

	"<quickWrappedBy: #QWWrappersExamples selector: #incrementerWrapper1:wrappedMethod:arguments:>"
	"<quickWrappedBy: #QWWrappersExamples selector: #incrementerWrapper2:wrappedMethod:arguments:>"
	"<quickWrappedBy: #QWWrappersExamples selector: #parenthesesWrapper:wrappedMethod:arguments:>"
	
	^ anObject
]
