     cmp  al, 31h
     jne  .e1
     mov  eax, 00320000h
     ret
.e1: cmp  al, 0
     jne  .e2
     mov  eax, 0FF200031h
     ret
.e2: mov  eax,00800000h
     ret
