/*	Generic Turing Emulator  C / C++ Header File
 *
 *	Copyright (c)   2015-2016    Lev Vorobyev
 */

/*
 *	Структура правила перехода
 *	a_fst, a_sec - Символы, записываемые на ленту
 *	dir - правило движения ленты
 *	первая лента: dir % 3: 0 - E, 1 - R, 2 - L
 *	вторая лента: dir / 3: 0 - E, 1 - R, 2 - L
 *	a_fst_const, a_sec_const - не менять значения на ленте
 *	f_repeat - нужно повторить вызов get_rule
 *	f_norule - правило не определено
 *	q_next - номер следующего состояния
 */
typedef struct {
	unsigned char a_fst : 8;
	unsigned char a_sec : 8;
	unsigned char dir : 4;
	unsigned char a_fst_const : 1;
	unsigned char a_sec_const : 1;
	unsigned char f_repeat : 1;
	unsigned char f_norule : 1;
	union {
		unsigned char tape_number : 8;
		struct {
			unsigned char q_number : 6;
			unsigned char q_flags : 2;
		} q_next;
	} lst_byte;
} rule_info;

typedef struct {
	char * cells;
	int index;
	unsigned int length;
} mtr_tape;

typedef void* mtr_handle;

typedef void (*mtr_callback)(int state, mtr_tape* lines);

#define ARR_SIZE	32

#ifdef __cplusplus
extern "C"
{
#endif	

/*
 * создает массив структур mtr_tape для заданной mtr_handle
 * в случае ошибки возвращает нулевой указатель
 */
mtr_tape * mtr_create(mtr_handle mtr, int length);

/*
 * переводит машину в исходное состояние
 */
extern void mtr_init(mtr_tape * lines);

/*
 * освобоздает память, выделенную под массив структур mtr_tape
 */
void mtr_free(mtr_tape * lines);

/*
 * увеличивает в два раза длину строки
 * в случае ошибки возврящает 0
 */
int mtr_tape_realloc(mtr_tape * line);

/*
 * эмулировать машину Тьюринга mtr на лентах lines с длиной length
 * возвращаемое значение - успешное выполнение - 0, иначе - номер состояния, в котором произошла ошибка, увеличенный на единицу
 */
extern int mtr_process(mtr_handle mtr, mtr_tape * tapes, mtr_callback callback);

#ifdef __cplusplus	
}
#endif

