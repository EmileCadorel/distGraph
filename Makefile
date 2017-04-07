all:
	dub build --parallel

all5:
	dub build --parallel --compiler=gdc-5

install:
	dub build --parallel --build=release
	dub add-local .

install5:
	dub build --parallel --build=release  --compiler=gdc-5
	dub add-local .

clean:
	dub clean
