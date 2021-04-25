;***********************************************;
;   Author: Natália Bubáková (xbubak01)         ;
;   Project: 1-dimensional cellular automata    ;
;   Date: 25.4.2021                             ;
;***********************************************;

%include "rw32-2020.inc"

section .data
    var_alive db "#",0                  ;premenná so znakom "ivej bunky" nachystaná pre vıpis knihovnou funkciou WriteString 
    var_dead db  "~",0                  ;premenná so znakom "màtvej bunky" ...
                                        ;vıber danıch znakov mi prišiel najvhodnejší kede pôvodné mi nevypisuje kontrastne, ale tu ich mono jednoducho zmeni za akéko¾vek iné
section .bss                            ;rezervuje miesto pre reazce, ktoré sa v programe budu naplnat; obyèajnou premennou by mohlo odjst k SEG chybe 
    arr resb 100                        ;premenná pre vstupnı reazec pre 1-bytove hodnoty o velkosti 100B
    arr2 resb 100                       ;premenná pre pomocnı reazec, ktory sa bude plnit na základe vstupného
    
section .text

_main:
    push ebp                            ;vytvorí zásobníkovı rámec (uloí pôvodnú hodnotu ebp)
    mov ebp, esp                        ;získa novu hodnotu ebp, pre moné manipulácie v programe 
                                        ;vo funkciach však toto nevytváram, pretoe v nich nepracujem so zásobníkom    

                                        ;nasledujúce funkcie nie su nevyhnutné, avšak zvolila som tento prístup pre preh¾adnos
    call process_input_foo              ;zavolá funkciu, ktorá spracuje šírku riadku zo vstupu
    
    call generate_random_foo            ;zavolá funkciu, ktorá vygeneruje prvı riadok s nepravidelnou postupnosou 0 a 1
    
the_loop:
    call go_through_arr_foo             ;funkcia prejde cez vstupnı reazec a na základe troj-kombinácii vyskladá pomocnı reazec
    
    call print_arr_foo                  ;funkcia vypíše reazec pomocou znakov reprezentujúcich ivé a mrtvé bunky

    call between_lines_foo              ;funkcia vymeni pomocnı reazec za hlavnı a odsadí riadok, aby sa cyklus mohol zopakova pre ïalší riadok
    
    jmp the_loop                        ;nepodmienenı skok, ktorı spôsobí, e riadky sa stále budú generova

    pop ebp                             ;upravenie zásobníka do pôvodného stavu
    ret                                 ;koniec programu



;******************************************;
;                FUNKCIE                   ;
;******************************************;

 process_input_foo:
        call ReadInt32                  ;zavolá knihovnú funkciu, ktorá zo vstupu preèíta 4B integer hodnotu reprezentujúcu šírku riadku a uloí ju do EAX registru
        cmp eax,10                      ;porovnanie vstupnej hodnoty s èíslom 10 pre nasledujúci podmienenı skok
        jl less                         ;ak je hodnota menšia ako desa skoèí
        cmp eax,100                     ;porovnanie vstupnej hodnoty s èíslom 100 pre nasledujúci podmienenı skok
        jg greater                      ;ak je hodnota väèšia ako sto skoèí
        jmp after_lg                    ;nepodmienenı skok pre zvyšne monosti v interval <10,100>, tak aby preskocilo nepotrebné úpravy
        
        less: 
        mov eax,10                      ;vloí èíslo 10 do registru EAX s pôvodnou vstupnou hodnotou
        jmp after_lg                    ;nepodmienenı skok pre preskoèenie nepotrebného
        greater:
        mov eax,100                     ;vloí èíslo 100 do registru EAX s pôvodnou vstupnou hodnotou
        
    after_lg:
        mov edx,eax                     ;register EDX bude po zvyšok programu uchováva vıslednú šírku riadku z EAX 
        
        ret
        
;*******************************************

 generate_random_foo:                   ;nepravidelnı rad 0 a 1 zaloenı na binárnej podobe postupnosti èísel zapoèínajúc od vstupnej hodnoty (šírka riadku) 
        
        mov ecx,0                       ;vynuluje register ECX ïalej vyuívané ako poèítadlo
    next_num:
        mov eax, edx                    ;vloi do EAX pôvodnu hodnotu
        add eax, ecx                    ;a zväèší o èíslo z poèítadla, aby sa hodnota neopakovala
    curr_num:
        mov bl,2                        ;ïalej robim s bytovımi hodnotami, tak mi staèi register BL (miesto EBX)
        div bl                          ;vydelim dané èíslo dvomi, tak aby som ich MOD mala v registri AH (AX/8bit register = AL, zvysok->AH)
        mov [arr + ecx],ah              ;vloí zvyšok z delenia (binárku) na miesto v poli arr urèeného poèítadlom
        mov ah,0                        ;vynuluje druhú polovicu registra AX tak, aby ïalej nenastali chyby v delení 
        inc ecx                         ;zvıši poèítadlo o jeden
        
        cmp ecx,edx                     ;ak šírka pola urèená poèítadlom je rovná potrebnej šírke
        je after_nums                   ;vyskoèí na koniec, ak nie, pokraèuje v cykle
        
        cmp al,0                        ;ako vısledok delenia nie je rovnı nule
        jne curr_num                    ;pokraèuje v dopoèítavaní aktuálneho èísla
                                 
        jmp next_num                    ;ak je, prebublá sem a skoèí na zmenu èísla
        
    after_nums:   
        ret                             ;návrat do mainu (bez vyuivania zásobníku samozrejme niè neriešime)

;**********************************************

 go_through_arr_foo:
        mov ecx,0                       ;vynuluje poèítadlo    
        
    ;**the first number**               ;prvú hodnotu poskladáme z N-tého, prvého a druhého prvku
        mov al,[arr+edx-1]              ;8bitovemu registru priradi N-tı prvok pola, kde N = hodnota v EDX - 1, lebo ECX poèíta od nuly
        mov bl,[arr]                    ;8bitovemu registru priradi 0-tı prvok pola
        shl al,1                        ;AL posunie o 1bit do ¾ava: 0000 000N -> 0000 00N0
        or al,bl                        ;AL a BL prejde cez logicku inštrukciu or,kde 0000 000N v 0000 00N0 -> 0000 00NN
        mov bl,[arr+1]                  ;rovnaky postup s ïalším prvkom
        shl al,1                        ; AL = 0000 00NN -> 0000 0NN0
        or al,bl                        ; AL = 0000 0NN0 v 0000 000N -> 0000 0NNN
        
        call compare_subfoo             ;zavolá pomocnú podfunkciu, ktorá trojici v registri BL priradí prislúchajúcu hodnotu (0/1) 
        mov [arr2],bl                   ;na nultı index pomocného reazca vloí odpovedajúcu hodnotu
        
        sub edx,2                       ;táto inštrukcia odèíta od celkovej šírky dva, predpripravené (pred cyklom, lebo nemusí zbytoène cykli) 
                                        ;pre riadok 117, kde potrebujem zistit hranicu celistvıch trojíc na konci riadku
    ;**in-between numbers**
    in_between:                         ;in between prvım a poslednım prvkom pomocného pola
        mov al,[arr+ecx]                ;znova berie trojicu èisel urèenu poèítadlom
        mov bl,[arr+ecx+1]              ;a rovnakım postupom vytvori binárku 
        shl al,1                        ;prišlo mi zbytoèné to robi cez cyklus a pod. 
        or al,bl                        ;aby som sa zbytoène nezamotala
        mov bl,[arr+ecx+2]
        shl al,1
        or al,bl
        
        call compare_subfoo             ;vıslednú trojicu znova vytriedi a priradí odpovedajúcu 1 alebo 0
        
        inc ecx                         ;tu sa poèítadlo zvaèšuje o jedna, aby prebehlo všetky trojice in-between        
        mov [arr2+ecx],bl               ;a priradí na odpovedajúcu pozíciu do pomocného pola priradenú hodnotu
                                        ;ecx=n, ecx+1=n+1, ecx+2=n+2, a potom 'inc ecx' správi zo strednej hodnoty n+1 -> n,a teda priradi na strednú - n-tú pozíciu danú 1 alebo 0 
        cmp ecx,edx                     ;porovná poèítadlo a prepripravenú hodnotu (šírka-2), èi nie sme na konci pravidelnıch trojíc 
        jne in_between                  ;ako nie, pokraèuje v cykle
                                        ;ako ano, vyskoèí z cyklu a ide na poslednı prvok pomocného pola        
        add edx,2                       ;obnoví pôvodnú šírku, aby kvôli jednej inštrukcii nebola skreslená pre zvyšné funkcie
        
     ;**the last number**
        mov al,[arr+ecx]                ;spraví znova presne to isté s poslednım prvkom
        mov bl,[arr+ecx+1]              ;a teda prepripraví binárku z predposledného, posledného a prvého(nultého) prvku hlavného pola
        shl al,1                        ;inštrukciu shl som vybrala, lebo pri takejto jednoduchej ulohe nepotrebujem ani rotovat ani ist cez CF, ale to by v podstate bolo jedno
        or al,bl                        ;inštrukcia OR mi správne zlúèi dve èísla do binárky ako potrebujem, ani súèet ani iná logická inštrukcia by nemala iaducé vısledky
        mov bl,[arr]
        shl al,1
        or al,bl
        
        call compare_subfoo             ;znova zavolá podfunkciu na porovnanie trojice s danımi modelmi
        mov [arr2+ecx+1],bl             ;a odpovedajúcu hodnotu z BL presunie na poslednú pozíciu pomocného pola
                                        ;ecx+1,lebo naposledy malo hodnotu n-2,a potrebujeme n-1, kede poèítame od nuly
        ret
        
;*******************   
                                        ;postupovala som podla RULE 30
 compare_subfoo:                        ;ale program je zostavenı univerzálne, take mono predpísané vzory jednoducho zmeni
        cmp al,111b                     ;tu porovná poskladanú hodnotu z trojice èísel s binárnou èíslicou odpovedajúcej šablóne
        je dead                         ;kde 1 prezentuje ivú bunku a 0 màtvu bunku
                                        ;ak sa hodnota rovná danej šablóne
        cmp al,110b                     ;skoèí pod¾a podmienky
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
        mov bl,byte 0                   ;ak odpovedá màtvej bunke, do BL registra priradí nulu
        ret                             ;a navráti sa z podfunkcie tak aby danú (dolnú strednú) hodnotu mohlo spracova
        
      alive:
        mov bl,byte 1                   ;ak odpovedá ivej bunke, do BL registra priradí jednotku
        ret                             ;a navráti na spracovanie
        
;***********************************************
    
 print_arr_foo:                         ;vıpis hlavného pola
        mov ecx,0                       ;vynuluje poèítadlo
        
    in_arr:
        mov al, [arr + ecx]             ;pre jednoduchšiu manipuláciu priraïujem danı prvok vypisovaného pola 8bitovému registru AL (lebo v poli sú 8bitove hodnoty)
      
        cmp al,0                        ;porovná prvok pola s 0
        jne one                         ;ak mu neodpovedá, je to jedna a tam aj skoèí
                                        ;inak pokraèuje a spracuje 0
        mov esi, var_dead               ;priradí pripravenú premennú - znak odpovedajúci màtvej bunke, do ESI registru pre vıpis s knihovnou funkciou WriteString
            
        jmp after_one                   ;nepodmienenım skokom preskoèí úpravu pri jednotkovej hodnote, pretoe ak sa dostal sem, bola spracovaná u nulová hodnot
      
      one:
        mov esi, var_alive              ;pri jednotke, priradí do registru ESI znak odpovedajúci ivej bunke, aby z neho mohla by ïalej vypísaná 
        
      after_one:
        call WriteString                ;zavolá knihovnú funkciu WriteString, ktorá berie odpovedajúci 'string' z ESI
                                        ;zvolila som túto funkciu, lebo sa s nou najlepšie manipulovalo pre dané úèely
                                        ;pre jednoduchı vıpis 0 a 1 z pola poslúi aj call WriteInt8 a s ním by ani nebolo treba podmienky a inštrukcie v riadkoch 179-190
      
        inc ecx                         ;poèítadlo sa o jedno navıši, aby mohlo dojs k vıpisu da¾šieho prvku pola
        cmp ecx,edx                     ;porovná aktuálnu hodnotu poèítadla so šírkou, èi náhodou nedošlo na koniec pola
        jne in_arr                      ;ak nie, pokraèuje v cykle
        
        ret                             ;ak áno, vyskoèí z cyklu a ide vráti sa do mainu pre pokraèovanie

;***********************************************
    
 between_lines_foo:                     ;medzi jendotlivımi riadkami vo velkom cykle
        call WriteNewLine               ;odsadí riadok
                                        ;a vymení polia, aby sa doterajšie pomocné pole stalo hlavnım
        mov esi,arr2                    ;funkcia movsb skopíruje pomocné pole z ESI
        mov edi,arr                     ;a vloí do pola nachystaného v EDI
                                        ;tu sa pıta 'mov ecx,edx' aby sa pole vymenilo do danej šírky, ale ecx je tak nastavené u z predošlej funkcie, take nemusíme nastavova znova
        rep movsb                       ;pod¾a poètu v ECX sa vïaka rep zopakuje inštrukcia potrebnıch poèet krát aby prehodila celé pole
     
                                        ;tu sa iada 'mov ecx,0', ale po poslednéj inštrukcií je ECX u vynulované, a tak môe ECX zas sluí ako poèítadlo
    empty_loop:                         ;prázdny cyklus pre zdranie vıpisu, aby to bolo lepšie vidie
        inc ecx                         ;zvyšuje poèítadlo v prázdnom cykle (nevadí e ide hned od 1, nezáleí na presnom poète)
        cmp ecx,0x0FFFFFFF              ;porovná s ve¾kım èíslom pre poadovanú 'fugu' vo vıpise
        jne empty_loop                  ;a pokia¾ poò nedojde toèí sa v cykle
        
        ret                             ;návrat do mainu, aby mohlo v cykle dojs k spracovaniu da¾šieho riadku
    
    
