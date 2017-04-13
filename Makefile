all:
	dub build --parallel

gdc:
	dub build --parallel --compiler=gdc-5

gdc6:
	dub build --parallel --compiler=gdc-6

install:
	dub build --parallel --build=release
	dub add-local .

install5:
	dub build --parallel --build=release  --compiler=gdc-5
	dub add-local .

clean:
	dub clean
