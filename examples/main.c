#include <stdio.h>
#include <statestep.h>
// increment -- программа для машины Тьюринга
extern mtr_handle increment;
int main() {
	// Для работы эмулятора необходимо создать ленты определенной длины
	mtr_tape * tapes = mtr_create(increment, 16);
	scanf("%s", tapes[0].line);
	// Эмуляция программы increment без функции обратного вызова
	mtr_process(increment, tapes, NULL);
	// Вывод на экран результатов работы прораммы
	printf("%s", tapes[0].line);
	// Перед выходом из программы необходимо освободить память
	mtr_free(tapes);
	return 0;
}