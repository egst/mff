bin/libmin.so: bin/libmin.o
	${CC} -o $@ -shared bin/libmin.o

bin/libmin.o: src/min.c
	${CC} -o $@ -I inc -c src/min.c