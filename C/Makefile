bin/libtest: libtest.c libs/bin/libmin.so
	${CC} -o $@ -I libs/inc -L libs/bin -Wl,-rpath libs/bin libtest.c -l min

.PHONY: minlib

minlib:
	@cd libs
	make -f libs/Makefile
	@cd ..
