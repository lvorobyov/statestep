INC = include

INC_PARAMS = -I../$(INC)

all: statestep.lib

statestep.obj: statestep.asm
	yasm -f win32 -o $@ $^

mtr_init.obj: mtr_init.asm
	yasm -f win32 -o $@ $^

mtr_alloc.o: mtr_alloc.c
	gcc -m32 -c $^ $(INC_PARAMS)

statestep.lib: mtr_alloc.o statestep.obj mtr_init.obj
	ar rc $@ $^
	ranlib $@