;***********************************************;
;   Author: Nat�lia Bub�kov� (xbubak01)         ;
;   Project: 1-dimensional cellular automata    ;
;   Date: 25.4.2021                             ;
;***********************************************;

%include "rw32-2020.inc"

section .data
    var_alive db "#",0                  ;premenn� so znakom "�ivej bunky" nachystan� pre v�pis knihovnou funkciou WriteString 
    var_dead db  "~",0                  ;premenn� so znakom "m�tvej bunky" ...
                                        ;v�ber dan�ch znakov mi pri�iel najvhodnej�� ked�e p�vodn� mi nevypisuje kontrastne, ale tu ich mo�no jednoducho zmeni� za ak�ko�vek in�
section .bss                            ;rezervuje miesto pre re�azce, ktor� sa v programe budu naplnat; oby�ajnou premennou by mohlo odjst k SEG chybe 
    arr resb 100                        ;premenn� pre vstupn� re�azec pre 1-bytove hodnoty o velkosti 100B
    arr2 resb 100                       ;premenn� pre pomocn� re�azec, ktory sa bude plnit na z�klade vstupn�ho
    
section .text

_main:
    push ebp                            ;vytvor� z�sobn�kov� r�mec (ulo�� p�vodn� hodnotu ebp)
    mov ebp, esp                        ;z�ska novu hodnotu ebp, pre mo�n� manipul�cie v programe 
                                        ;vo funkciach v�ak toto nevytv�ram, preto�e v nich nepracujem so z�sobn�kom    

                                        ;nasleduj�ce funkcie nie su nevyhnutn�, av�ak zvolila som tento pr�stup pre preh�adnos�
    call process_input_foo              ;zavol� funkciu, ktor� spracuje ��rku riadku zo vstupu
    
    call generate_random_foo            ;zavol� funkciu, ktor� vygeneruje prv� riadok s nepravidelnou postupnos�ou 0 a 1
    
the_loop:
    call go_through_arr_foo             ;funkcia prejde cez vstupn� re�azec a na z�klade troj-kombin�cii vysklad� pomocn� re�azec
    
    call print_arr_foo                  ;funkcia vyp�e re�azec pomocou znakov reprezentuj�cich �iv� a mrtv� bunky

    call between_lines_foo              ;funkcia vymeni pomocn� re�azec za hlavn� a odsad� riadok, aby sa cyklus mohol zopakova� pre �al�� riadok
    
    jmp the_loop                        ;nepodmienen� skok, ktor� sp�sob�, �e riadky sa st�le bud� generova�

    pop ebp                             ;upravenie z�sobn�ka do p�vodn�ho stavu
    ret                                 ;koniec programu



;******************************************;
;                FUNKCIE                   ;
;******************************************;

 process_input_foo:
        call ReadInt32                  ;zavol� knihovn� funkciu, ktor� zo vstupu pre��ta 4B integer hodnotu reprezentuj�cu ��rku riadku a ulo�� ju do EAX registru
        cmp eax,10                      ;porovnanie vstupnej hodnoty s ��slom 10 pre nasleduj�ci podmienen� skok
        jl less                         ;ak je hodnota men�ia ako desa� sko��
        cmp eax,100                     ;porovnanie vstupnej hodnoty s ��slom 100 pre nasleduj�ci podmienen� skok
        jg greater                      ;ak je hodnota v��ia ako sto sko��
        jmp after_lg                    ;nepodmienen� skok pre zvy�ne mo�nosti v interval <10,100>, tak aby preskocilo nepotrebn� �pravy
        
        less: 
        mov eax,10                      ;vlo�� ��slo 10 do registru EAX s p�vodnou vstupnou hodnotou
        jmp after_lg                    ;nepodmienen� skok pre presko�enie nepotrebn�ho
        greater:
        mov eax,100                     ;vlo�� ��slo 100 do registru EAX s p�vodnou vstupnou hodnotou
        
    after_lg:
        mov edx,eax                     ;register EDX bude po zvy�ok programu uchov�va� v�sledn� ��rku riadku z EAX 
        
        ret
        
;*******************************************

 generate_random_foo:                   ;nepravideln� rad 0 a 1 zalo�en� na bin�rnej podobe postupnosti ��sel zapo��naj�c od vstupnej hodnoty (��rka riadku) 
        
        mov ecx,0                       ;vynuluje register ECX �alej vyu��van� ako po��tadlo
    next_num:
        mov eax, edx                    ;vlo�i do EAX p�vodnu hodnotu
        add eax, ecx                    ;a zv��� o ��slo z po��tadla, aby sa hodnota neopakovala
    curr_num:
        mov bl,2                        ;�alej robim s bytov�mi hodnotami, tak mi sta�i register BL (miesto EBX)
        div bl                          ;vydelim dan� ��slo dvomi, tak aby som ich MOD mala v registri AH (AX/8bit register = AL, zvysok->AH)
        mov [arr + ecx],ah              ;vlo�� zvy�ok z delenia (bin�rku) na miesto v poli arr ur�en�ho po��tadlom
        mov ah,0                        ;vynuluje druh� polovicu registra AX tak, aby �alej nenastali chyby v delen� 
        inc ecx                         ;zv��i po��tadlo o jeden
        
        cmp ecx,edx                     ;ak ��rka pola ur�en� po��tadlom je rovn� potrebnej ��rke
        je after_nums                   ;vysko�� na koniec, ak nie, pokra�uje v cykle
        
        cmp al,0                        ;ako v�sledok delenia nie je rovn� nule
        jne curr_num                    ;pokra�uje v dopo��tavan� aktu�lneho ��sla
                                 
        jmp next_num                    ;ak je, prebubl� sem a sko�� na zmenu ��sla
        
    after_nums:   
        ret                             ;n�vrat do mainu (bez vyu�ivania z�sobn�ku samozrejme ni� nerie�ime)

;**********************************************

 go_through_arr_foo:
        mov ecx,0                       ;vynuluje po��tadlo    
        
    ;**the first number**               ;prv� hodnotu posklad�me z N-t�ho, prv�ho a druh�ho prvku
        mov al,[arr+edx-1]              ;8bitovemu registru priradi N-t� prvok pola, kde N = hodnota v EDX - 1, lebo ECX po��ta od nuly
        mov bl,[arr]                    ;8bitovemu registru priradi 0-t� prvok pola
        shl al,1                        ;AL posunie o 1bit do �ava: 0000 000N -> 0000 00N0
        or al,bl                        ;AL a BL prejde cez logicku in�trukciu or,kde 0000 000N v 0000 00N0 -> 0000 00NN
        mov bl,[arr+1]                  ;rovnaky postup s �al��m prvkom
        shl al,1                        ; AL = 0000 00NN -> 0000 0NN0
        or al,bl                        ; AL = 0000 0NN0 v 0000 000N -> 0000 0NNN
        
        call compare_subfoo             ;zavol� pomocn� podfunkciu, ktor� trojici v registri BL prirad� prisl�chaj�cu hodnotu (0/1) 
        mov [arr2],bl                   ;na nult� index pomocn�ho re�azca vlo�� odpovedaj�cu hodnotu
        
        sub edx,2                       ;t�to in�trukcia od��ta od celkovej ��rky dva, predpripraven� (pred cyklom, lebo nemus� zbyto�ne cykli�) 
                                        ;pre riadok 117, kde potrebujem zistit hranicu celistv�ch troj�c na konci riadku
    ;**in-between numbers**
    in_between:                         ;in between prv�m a posledn�m prvkom pomocn�ho pola
        mov al,[arr+ecx]                ;znova berie trojicu �isel ur�enu po��tadlom
        mov bl,[arr+ecx+1]              ;a rovnak�m postupom vytvori bin�rku 
        shl al,1                        ;pri�lo mi zbyto�n� to robi� cez cyklus a pod. 
        or al,bl                        ;aby som sa zbyto�ne nezamotala
        mov bl,[arr+ecx+2]
        shl al,1
        or al,bl
        
        call compare_subfoo             ;v�sledn� trojicu znova vytriedi a prirad� odpovedaj�cu 1 alebo 0
        
        inc ecx                         ;tu sa po��tadlo zva�uje o jedna, aby prebehlo v�etky trojice in-between        
        mov [arr2+ecx],bl               ;a prirad� na odpovedaj�cu poz�ciu do pomocn�ho pola priraden� hodnotu
                                        ;ecx=n, ecx+1=n+1, ecx+2=n+2, a potom 'inc ecx' spr�vi zo strednej hodnoty n+1 -> n,a teda priradi na stredn� - n-t� poz�ciu dan� 1 alebo 0 
        cmp ecx,edx                     ;porovn� po��tadlo a prepripraven� hodnotu (��rka-2), �i nie sme na konci pravideln�ch troj�c 
        jne in_between                  ;ako nie, pokra�uje v cykle
                                        ;ako ano, vysko�� z cyklu a ide na posledn� prvok pomocn�ho pola        
        add edx,2                       ;obnov� p�vodn� ��rku, aby kv�li jednej in�trukcii nebola skreslen� pre zvy�n� funkcie
        
     ;**the last number**
        mov al,[arr+ecx]                ;sprav� znova presne to ist� s posledn�m prvkom
        mov bl,[arr+ecx+1]              ;a teda prepriprav� bin�rku z predposledn�ho, posledn�ho a prv�ho(nult�ho) prvku hlavn�ho pola
        shl al,1                        ;in�trukciu shl som vybrala, lebo pri takejto jednoduchej ulohe nepotrebujem ani rotovat ani ist cez CF, ale to by v podstate bolo jedno
        or al,bl                        ;in�trukcia OR mi spr�vne zl��i dve ��sla do bin�rky ako potrebujem, ani s��et ani in� logick� in�trukcia by nemala �iaduc� v�sledky
        mov bl,[arr]
        shl al,1
        or al,bl
        
        call compare_subfoo             ;znova zavol� podfunkciu na porovnanie trojice s dan�mi modelmi
        mov [arr2+ecx+1],bl             ;a odpovedaj�cu hodnotu z BL presunie na posledn� poz�ciu pomocn�ho pola
                                        ;ecx+1,lebo naposledy malo hodnotu n-2,a potrebujeme n-1, ked�e po��tame od nuly
        ret
        
;*******************   
                                        ;postupovala som podla RULE 30
 compare_subfoo:                        ;ale program je zostaven� univerz�lne, tak�e mo�no predp�san� vzory jednoducho zmeni�
        cmp al,111b                     ;tu porovn� poskladan� hodnotu z trojice ��sel s bin�rnou ��slicou odpovedaj�cej �abl�ne
        je dead                         ;kde 1 prezentuje �iv� bunku a 0 m�tvu bunku
                                        ;ak sa hodnota rovn� danej �abl�ne
        cmp al,110b                     ;sko�� pod�a podmienky
        je dead     
        
        cmp al,101b
        je dead
        
        cmp al,100b
        je alive
        
        cmp al,011b
        je alive
        
        cmp al,010b
        je alive
        
        cmp al,001b
        je alive
        
        cmp al,000b
        je dead
        
      dead:
        mov bl,byte 0                   ;ak odpoved� m�tvej bunke, do BL registra prirad� nulu
        ret                             ;a navr�ti sa z podfunkcie tak aby dan� (doln� stredn�) hodnotu mohlo spracova�
        
      alive:
        mov bl,byte 1                   ;ak odpoved� �ivej bunke, do BL registra prirad� jednotku
        ret                             ;a navr�ti na spracovanie
        
;***********************************************
    
 print_arr_foo:                         ;v�pis hlavn�ho pola
        mov ecx,0                       ;vynuluje po��tadlo
        
    in_arr:
        mov al, [arr + ecx]             ;pre jednoduch�iu manipul�ciu prira�ujem dan� prvok vypisovan�ho pola 8bitov�mu registru AL (lebo v poli s� 8bitove hodnoty)
      
        cmp al,0                        ;porovn� prvok pola s 0
        jne one                         ;ak mu neodpoved�, je to jedna a tam aj sko��
                                        ;inak pokra�uje a spracuje 0
        mov esi, var_dead               ;prirad� pripraven� premenn� - znak odpovedaj�ci m�tvej bunke, do ESI registru pre v�pis s knihovnou funkciou WriteString
            
        jmp after_one                   ;nepodmienen�m skokom presko�� �pravu pri jednotkovej hodnote, preto�e ak sa dostal sem, bola spracovan� u� nulov� hodnot
      
      one:
        mov esi, var_alive              ;pri jednotke, prirad� do registru ESI znak odpovedaj�ci �ivej bunke, aby z neho mohla by� �alej vyp�san� 
        
      after_one:
        call WriteString                ;zavol� knihovn� funkciu WriteString, ktor� berie odpovedaj�ci 'string' z ESI
                                        ;zvolila som t�to funkciu, lebo sa s nou najlep�ie manipulovalo pre dan� ��ely
                                        ;pre jednoduch� v�pis 0 a 1 z pola posl��i aj call WriteInt8 a s n�m by ani nebolo treba podmienky a in�trukcie v riadkoch 179-190
      
        inc ecx                         ;po��tadlo sa o jedno nav��i, aby mohlo dojs� k v�pisu da��ieho prvku pola
        cmp ecx,edx                     ;porovn� aktu�lnu hodnotu po��tadla so ��rkou, �i n�hodou nedo�lo na koniec pola
        jne in_arr                      ;ak nie, pokra�uje v cykle
        
        ret                             ;ak �no, vysko�� z cyklu a ide vr�ti sa do mainu pre pokra�ovanie

;***********************************************
    
 between_lines_foo:                     ;medzi jendotliv�mi riadkami vo velkom cykle
        call WriteNewLine               ;odsad� riadok
                                        ;a vymen� polia, aby sa doteraj�ie pomocn� pole stalo hlavn�m
        mov esi,arr2                    ;funkcia movsb skop�ruje pomocn� pole z ESI
        mov edi,arr                     ;a vlo�� do pola nachystan�ho v EDI
                                        ;tu sa p�ta 'mov ecx,edx' aby sa pole vymenilo do danej ��rky, ale ecx je tak nastaven� u� z predo�lej funkcie, tak�e nemus�me nastavova� znova
        rep movsb                       ;pod�a po�tu v ECX sa v�aka rep zopakuje in�trukcia potrebn�ch po�et kr�t aby prehodila cel� pole
     
                                        ;tu sa �iada 'mov ecx,0', ale po posledn�j in�trukci� je ECX u� vynulovan�, a tak m��e ECX zas slu�� ako po��tadlo
    empty_loop:                         ;pr�zdny cyklus pre zdr�anie v�pisu, aby to bolo lep�ie vidie�
        inc ecx                         ;zvy�uje po��tadlo v pr�zdnom cykle (nevad� �e ide hned od 1, nez�le�� na presnom po�te)
        cmp ecx,0x0FFFFFFF              ;porovn� s ve�k�m ��slom pre po�adovan� 'fugu' vo v�pise
        jne empty_loop                  ;a pokia� po� nedojde to�� sa v cykle
        
        ret                             ;n�vrat do mainu, aby mohlo v cykle dojs� k spracovaniu da��ieho riadku
    
    
