all:
	dub build --parallel --compiler=gdc-5 --config=master
	dub build --parallel --compiler=gdc-5 --config=slave

dmd:
	dub build --parallel --config=master --build=release
	dub build --parallel --config=slave --build=release

release:
	dub build --parallel --compiler=gdc-5 --config=master --build=release
	dub build --parallel --compiler=gdc-5 --config=slave --build=release

