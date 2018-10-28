INC = include
LIB = lib

INC_PARAMS = -I..\$(INC)
LIB_PARAMS = -L..\$(LIB)

all: increment.exe

increment.obj: increment.asm
	yasm -f win32 -o $@ $^

main.o: main.c
	gcc -m32 -c $^ $(INC_PARAMS)

increment.exe: main.o increment.obj
	gcc -o $@ $^ $(LIB_PARAMS) -lstatestep 
	
clean: 
	del *.o