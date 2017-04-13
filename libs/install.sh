if [ -a libmpi.lib ]; then
    rm libmpi.lib
fi

mpicc -c mpiwrap.c
mpicc -c -g mpiwrap.c -o mpiwrap.g.o
#ar crU libmpi.lib mpiwrap.o mpiwrap.g.o
#ranlib libmpi.lib
cp *.o ${HOME}/libs/
