
# if [ ! -d  "${HOME}/libs" ]; then
#     mkdir ${HOME}/libs
#     echo "Creation du dossier ~/libs"
# fi

#cd libs
#./install.sh
#cd ..

dub add-local .
cd dsl
dub add-local .
make
cp dsl ~/libs/

export PATH=~/libs/:$PATH:.

# cp findPort.sh ~/libs/
