
if [ ! -d  "${HOME}/libs" ]; then
    mkdir ${HOME}/libs
    echo "Creation du dossier ~/libs"
fi

cp libs/libmpi.lib ${HOME}/libs/
dub add-local .
