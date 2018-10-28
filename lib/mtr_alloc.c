#include <stdlib.h>
#include <statestep.h>

mtr_tape * mtr_create(mtr_handle mtr, int length)
{
	int i;
	int tape_count = *((int*)mtr);
	mtr_tape * tapes;
	if(!(tapes = (mtr_tape*) malloc(sizeof(mtr_tape) * tape_count + sizeof(char*))))
		return NULL;
	for(i=0; i<tape_count; i++) {
		if(!(tapes[i].cells = (char*) malloc(length)))
		{
			while(--i>=0) {
				free(tapes[i].cells);
			}
			free(tapes);
			return NULL;
		}
		tapes[i].length = length;
	}
	tapes[tape_count].cells = NULL;
	mtr_init(tapes);
	return tapes;
}

void mtr_free(mtr_tape * tapes)
{
	mtr_tape * ptr = tapes;
	while(ptr->cells) {
		free(ptr++ -> cells);
	}
	free(tapes);
}

int mtr_tape_realloc(mtr_tape * tape)
{
	char* ptr = (char*) realloc(tape->cells, tape->length*2);
	// TODO: возможно, вновь добавленные байты следует заполнить нулями
	if(!ptr){
		return 0;
	}
	tape->cells = ptr;
	tape->length = tape->length*2;
	return 1;
}