Class {
	#name : #BaselineOfQuickWrap,
	#superclass : #BaselineOf,
	#category : #BaselineOfQuickWrap
}

{ #category : #baselines }
BaselineOfQuickWrap >> baseline: spec [

	<baseline>
	spec for: #common do: [ 
		spec
			baseline: 'MethodProxies'
			with: [ spec repository: 'github://maxwills/MethodProxies/src' ].
		spec
			package: 'QuickWrap'
			with: [ spec requires: #( 'MethodProxies' ) ] ]
]
