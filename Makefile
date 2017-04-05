all:
	dub build --parallel

all5:
	dub build --parallel --compiler=gdc-5

final:
	dub build --parallel --build=release


final5:
	dub build --parallel --build=release  --compiler=gdc-5

clean:
	dub clean
