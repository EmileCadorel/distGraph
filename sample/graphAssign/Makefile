all:
	dub build --parallel

dmd:
	dub build --parallel 

ldc2:
	dub build --parallel --compiler=ldc2 

gdc6:
	dub build --parallel --compiler=gdc-6 

release-dmd:
	dub build --parallel --build=release

release:
	dub build --parallel --build=release --compiler=gdc-5

release6:
	dub build --parallel --compiler=gdc-6 --build=release


release2:
	dub build --parallel --compiler=ldc2 --build=release


force:
	dub build --parallel --force


profile:
	dub build --build=profile

profile-gc:
	dub build --build=profile-gc

verbose:
	dub build -v 
