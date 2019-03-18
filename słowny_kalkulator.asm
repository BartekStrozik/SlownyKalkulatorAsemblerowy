dane1 segment

	wejscie	db	30                      ;
			db	?                       ;bufor do zapisywania zadanego dzialania przez uzytkownika
			db	31 dup ('$')            ;
	
	operand1 db 20 dup ('$')            ;
    dzialanie db 20 dup ('$')           ;skladowe, do ktorych rozbije dzialanie, aby latwiej sparsowac
    operand2 db 20 dup ('$')            ;
    
    spacja1 db '#'                      
    spacja2 db '#'                      ;indeksy spacji, po nich oblicze, gdzie koncza sie skladowe
    
    ;tablice z zakresem dostepnych-dozwolonych wartosci: wprowadzanych liczb, operatora oraz wyprowadzanego wyniku
    
    cyfry db "zero$$$$$","jeden$$$$","dwa$$$$$$","trzy$$$$$","cztery$$$","piec$$$$$","szesc$$$$","siedem$$$","osiem$$$$","dziewiec$","#$"  ;uzupelniane do 9 bajtow
    
    operatory db "plus$$$$$","minus$$$$","razy$$$$$","#$"                                                             ;uzupelniane do 9 bajtow rowniez
    
    dziesiatki db "dwadziescia$$$$$$","trzydziesci$$$$$$","czterdziesci$$$$$","piecdziesiat$$$$$","szescdziesiat$$$$","siedemdziesiat$$$","osiemdziesiat$$$$","dziewiecdziesiat$",    ;te z kolei do 17 bajtow
    
    nascie db "dziesiec$$$$$$$","jedenascie$$$$$","dwanascie$$$$$$","trzynascie$$$$$","czternascie$$$$","pietnascie$$$$$","szesnascie$$$$$","siedemnascie$$$","osiemnascie$$$$","dziewietnascie$" ;te sa uzupelniane do 15 bajtow
    
    minus db 'minus $'
	
	spacja db ' $'
	
	komunikat db 'Wprowadz slowny opis dzialania: $'
	wynik db 'Wynikiem jest: $'
	blad db 'Bledne dane wejsciowe!$'
dane1 ends


kod1 segment
    
;=======================================================================================================================================================================
;=======================================================================================================================================================================

start:
	;przenies segment top1 do segmentu stosu
	mov ax,seg top1
	mov ss,ax			;przenies segement stosu do rejestru segmentowego
	mov sp,offset top1	;przenies offset stosu do rejestru wskaznikowego
	
	;przenies segment danych do rejstru ds   
	mov ax,seg wejscie
	mov ds,ax   
	 
	 
	;**********************ETAP 1: WCZYTANIE DZIALANIA I ZNALEZIENIE SPACJI***********************
	
	mov ah,09h
	lea dx,komunikat
	int 21h
	   
	;wczytaj wyrazenie arytmetyczne slowne od uzytkownika
	mov ah,0ah
	lea dx,wejscie
	int 21h
	
	;nowa linia
	mov ah,02h
	mov dl,0ah
	int 21h
	mov dl,0dh
	int 21h
	
	;ustawiam poczatek napisu do rejestru SI celem przeskanowania go i znalezienia spacji
	lea si,wejscie+2
	
	;ustawiam licznik petli tak, zeby odczytywac wszystkie bajty z wprowadzonego wyrazenia
	xor cx,cx
	mov cl,byte ptr ds:[wejscie+1]      ;liczbe iteracji petli ustawiam na liczbe bajtow wejscia
	mov bl,0                            ;zmienna pomocnicza do okreslania indeksow spacji
	szukanie_spacji:
	    mov dl,byte ptr [si]
	    cmp dl,' '                      ;sprawdzam czy znak jest spacja
	    jne inkrementuj                 ;jak nie, to nie ustawiam spacji, tylko szukam dalej
	    
	    mov dl,byte ptr ds:[spacja1]    ;ustawiam spacje! co mam jak na razie w pierwszej?
	    cmp dl,'#'                      ;sprawdzam, czy jeszcze nic
	    jne druga                       ;jak cos mam, bo nie ma # to ustawiam druga
	    
	    mov byte ptr ds:[spacja1],bl    ;jak nic nie ma, bo jest # to ustawiam pierwsza
	    jmp inkrementuj
	    
	    druga:
	        mov byte ptr ds:[spacja2],bl    ;pierwsza byla ustawiona, wiec ustawiam druga
	    
	    inkrementuj:
	        inc bl                      ;zwiekszam zmienna pomocnicza do okreslenia indeksu
	        inc si                      ;przechodze do kolejnego bajtu wejscia
	loop szukanie_spacji
	
	mov dl,byte ptr ds:[spacja1]
	cmp dl,'#'
	je bledne_dane
	
	cmp dl,0
	je bledne_dane
	
	mov dl,byte ptr ds:[spacja2]
	cmp dl,'#'
	je bledne_dane
	
	;**********************ETAP 2: ROZBICIE DZIALANIA NA 3 SKLADOWE***********************
	
	
	;PIERWSZA SKLADOWA
	;przepisanie pierwszego czlona napisu do operanda1
	
	lea si,wejscie+2                    ;rejestr SI ustawiamy na poczatkowy bajt wejscia
	lea di,operand1                     ;bierzemy na tapete pierwszy operand
	
	xor cx,cx                           ;cx=0
	mov cl,byte ptr ds:[spacja1]        ;indeks pierwszej spacji to dlugosc pierwszego napisu (zawsze!)
	
	wyciagnij_pierwsza_liczbe:
	    call wyciagaj                   ;wywolanie procedury
	loop wyciagnij_pierwsza_liczbe
	 
	;DRUGA SKLADOWA
	;przepisanie drugiego czlona napisu do operatora dzialania
	
	inc si                             ;omijam spacje                             
	lea di,dzialanie                   ;pora na operator
	
	xor cx,cx
	mov cl,byte ptr ds:[spacja2]       ;dlugosc napisu do 2. spacji = operand1+1+dzialanie
	sub cl,byte ptr ds:[spacja1]       ;(operand1+1+dzialanie) - operand1 = 1+dzialanie
	sub cl,1                           ;(1+dzialanie) - 1 = dzialanie :)
	
	wyciagnij_operator_dzialania:
	    call wyciagaj    
	loop wyciagnij_operator_dzialania
	
	;TRZECIA SKLADOWA
	;przepisanie trzeciego czlona napisu do drugiego operanda
	
	inc si                            ;omijamy druga spacyjke
	lea di,operand2                   ;kolej na operand numero duo!
	
	xor cx,cx
	mov cl,byte ptr ds:[wejscie+1]    ;bierzemy caaala dlugosc napisu: operand1 + 1 + dzialanie + 1 + operand2
	sub cl,byte ptr ds:[spacja2]      ;pozostalo 1 + operand2
	sub cl,1                          ;mamy co trzeba :D (czyli dlugosc operanda)
	
	;mov cl,3
	wyciagnij_druga_liczbe:
	    call wyciagaj    
	loop wyciagnij_druga_liczbe
	
	
	
	;**********************************ETAP 3: PARSOWANIE (SLOWA -> LICZBY)*************************************
	
	
	;PARSOWANIE PIERWSZEGO OPERANDA
	mov ax,seg cyfry        
	mov es,ax               ;w konkatenacji rejestrow: ES:DI bede przechowywac dozwolone cyfry, do dopasowania 
	mov ax,seg operand1
	mov ds,ax               ;z kolei w DS:SI operand, ktory zamierzam sparsowac
	
	cld                     ;czyszcze flage kierunku po to, by przechodzic od poczatku do konca napisow
	lea dx,cyfry            ;za pomoca DX, bede skakac offsetem co 6 bajtow do kolejnych cyfr
	mov al,0                ;w AL bede trzymac kandydujaca wartosc liczbowa parsowanej liczby
	
	parsuj_operand1:
	    lea si,operand1     ;zgodnie z obietnica w ES:DI pierwszy operand :)
	    call parsuj         
	    cmp ah,0            ;udalo sie sparsowac
	    je wyjdz1
	jmp parsuj_operand1
	
	wyjdz1:
	    mov bl,al           ;w BL trzymam pierwsza wartosc
	
	;PARSOWANIE DRUGIEGO OPERANDA    
	mov ax,seg cyfry
	mov es,ax               ;analogicznie
	mov ax,seg operand2
	mov ds,ax               ;analogicznie
	
    cld
    lea dx,cyfry            ;analogicznie
    mov al,0
    
    parsuj_operand2:
		lea si,operand2
        call parsuj
        cmp ah,0
        je wyjdz2
    jmp parsuj_operand2
	
	wyjdz2:
	    mov bh,al           ;w BH trzymam druga wartosc
    
    ;tym sposobem uzyskalem podane przez uzytkownika wartosci, ktore przechowuje liczbowo w rejestrze BX
    
    ;PARSOWANIE OPERATORA  
	mov ax,seg operatory
	mov es,ax
	mov ax,seg dzialanie
	mov ds,ax
	
	cld
	lea dx,operatory
	mov al,0                ;w tym przypadku AL posluzy jako znacznik operatora, konkretnie:
	                        ;AL=0 oznacza dodawanie, AL=1 oznacza odejmowanie, AL=2 oznacza mnozenie
	
	parsuj_dzialanie:
	    lea si,dzialanie
	    call parsuj
	    cmp ah,0
	    je licz
	jmp parsuj_dzialanie
	
	;**********************************ETAP 4: LICZENIE I KOMUNIKAT O WYNIKU*************************************
	
	;ostatecznie wynik liczbowy dzialania zapisze do AX, z uwagi na estetyke zerujemy AH (AL wystarczy do zapamietania wyniku),
	;przy czym przy mnozeniu nie jest to konieczne - zapisuje ono wynik w calym rejestrze AX
	
	licz:
	    cmp al,0
	    je dodaj
	    cmp al,1
	    je odejmij
	    cmp al,2
	    je pomnoz
	    
	dodaj:
	    add bl,bh           ;BL = BL + BH
	    mov al,bl           ;
	    mov ah,0            ;AX = BL (wynik w AX)
	    jmp komunikat_wynik
	
	odejmij:
	    sub bl,bh           ;BL = BL - BH
	    mov al,bl           ;
	    mov ah,0            ;AX = BL (wynik w AX)
	    jmp komunikat_wynik
	
	pomnoz:
	    mov al,bl
	    mul bh              ;AX = AL * BH (wynik w AX)
	    
	
	;w tym momencie mam wynik dzialania uzytkownika, jego wartosc przechowuje w AX
	;zadna inna informacja sie nie liczy
	
	;komunikat o wyniku:
	
	komunikat_wynik:
	mov bx,ax
	
	mov ah,09h
	lea dx,wynik
	int 21h
	
	mov ax,bx
	
	;**********************************ETAP 5: NAPRAWIENIE LICZB UJEMNYCH WYNIKU*************************************
	
	;najpierw sprawdzam, czy nie wyszla liczba ujemna
	mov bx,246d         ;jest to wartosc dla -10, ktora przenigdy nie wystapi w programie (beda wylacznie od niej wieksze)
	
	sub bx,ax           ;BX = AX - BX 
	ja nieujemna        ;jak wynik bedzie dodatni to wynik jest nieujemny i wychodzimy z tej sekcji
	
	;zmienna pomocnicza, w BX przechowujemy AX
	
	mov bl,al
    mov bh,0
	
	;wypisanie minusa
	
	lea dx,minus
	mov ah,09h
	int 21h	
    
    ;naprawienie liczby ujemnej - sprowadzam ja z powrotem do odpowiedniej liczby nieujemnej
    ;minus i tak mamy juz zaznaczony
    ;wiec pozniej bede postepowac z ta liczba jakby normalnie byla nieujemna
    
    mov ax,100h
    sub ax,bx
	
	
	;**********************************ETAP 6: WYPISYWANIE*************************************
	
	
	nieujemna:
	;w pierwszej kolejnosci rozbijemy wynik w AX na cyfre dziesiatek i cyfre jednosci
	mov dl,10d
	div dl                  ;AL <- cyfra dziesiatek, AH <- cyfra jednosci
	
	cmp al,1
	jne wypisz_dziesiatki
	
	;++++++++++++++++++++++++++++++++LICZBY NASCIE++++++++++++++++++++++++++++++++++++
	
	wypisz_nascie:
	mov al,ah               ;cyfre jednosci przenosimy ze starszego bajtu AX do mlodszego
	mov dl,15d              ;rozmiar kazdego napisu
	mul dl                  ;mnozymy do otrzymania pelnego przesuniecia do wlasciwej nazwy liczby
	
	mov cl,al               ;AX bedziemy oczywiscie wykorzystywac
	mov ch,0                ;do przesuniecia wykorzystamy CX
	
	mov ax,seg nascie
	mov ds,ax               ;upewniamy sie ze mamy odpowiedni segment danych w DS (wczesniej sporo sie tym bawilismy)
	lea dx,nascie           ;w DX tablica, z ktorej chcemy wypisac
	add dx,cx               ;przejscie do odpowiedniego elementu tablicy
	
	mov ah,09h              ;wypisanie
	int 21h
	jmp zakoncz
	
	;++++++++++++++++++++++++++++++++LICZBY NASCIE++++++++++++++++++++++++++++++++++++ 
	
	
	;++++++++++++++++++++++++++++++++LICZBY DZIESIATKI++++++++++++++++++++++++++++++++++++
	
	wypisz_dziesiatki:
	
	mov cl,ah               ;ZMIENNA TYMCZASOWA-POMOCNICZA na cyfre jednosci
	
	cmp al,0                ;gdy liczba jest mniejsza od 10 wypisz tylko cyfre jednosci
	je wypisz_jednosci
	
	sub al,2                ;nazwy dziesiatek zaczynaja sie od twenty, czyli 0->twenty, 1->thirty, 2->fourty
	mov dl,17                ;offset nazw dziesiatek
	mul dl                  ;mnozymy przez 8 - dzieki temy w AX przechowujemy offset od poczatku do pozadanej nazwy
	
	mov bl,al               ;AX nam sie niestety przyda wobec czego przenosimy go do BX
	mov bh,0
	
	mov ax,seg dziesiatki
	mov ds,ax
	lea dx,dziesiatki
	add dx,bx               ;teraz zwiekszam w tablicy dziesiatki o BX, czyli offset, przesuniecie do odpowiedniego napisu
	
	mov ah,9                
	int 21h
	
	cmp cl,0				;nie wypisuj zera po cyfrze dziesiatek (unikamy sytuacji wypisania wyniku np. trzydziesci zero)
	je zakoncz
	
	lea dx,spacja
	mov ah,9
	int 21h
	;++++++++++++++++++++++++++++++++LICZBY DZIESIATKI++++++++++++++++++++++++++++++++++++
	
	
	;++++++++++++++++++++++++++++++++LICZBY JEDNOSCI++++++++++++++++++++++++++++++++++++
	
	;WYPISANIE CYFRY JEDNOSCI
	wypisz_jednosci:
	
	mov al,cl               ;pobieramy cyfre jednosci
	mov dl,9                ;offset nazw cyfr
	mul dl                  ;w AX przesuniecie do pozadanej nazwy
		
	mov cl,al               ;AX sie przyda, przesuniecie bedziemy przechowywac w CX
	mov ch,0
	
	mov ax,seg cyfry
	mov ds,ax
	lea dx,cyfry
	add dx,cx
	
	mov ah,9
	int 21h
	
	jmp zakoncz
	;++++++++++++++++++++++++++++++++LICZBY JEDNOSCI++++++++++++++++++++++++++++++++++++
	
	bledne_dane:
	mov ah,09h
	lea dx,blad
	int 21h
	
	;zakoncz program
	zakoncz:
	mov	ah,04ch                        ;koniec :D
	int 21h
	
;=======================================================================================================================================================================
;=======================================================================================================================================================================
	
	;PROCEDURY
	
	wyciagaj:
	    mov dl,byte ptr [si]            ;rejestr DL sluzy za zmienna pomocnicza
		cmp dl,' '						;gdy na wejsciu mamy spacje wiodace danej skladowej
		je opoznij						;opozniamy wyciaganie skladowej
	    
		mov byte ptr [di],dl            ;przepisujemy za jego pomoca wejscie do pierwszej skladowej
	    inc di
		
		opoznij:
	    inc si
	    ret
	
	parsuj:
	    mov ah,1                ;AH to flaga: przypuszczam tutaj, ze parsowanie sie NIE uda
	    mov di,dx;              ;DX przesuwa sie po tablicy, wiec do DI trafia kolejny jej element
		
		cmp byte ptr[di],'#'
		je bledne_dane
		
	    xor cx,cx	
	    mov cx,9                ;ustawiam rejestr CX na 9, bo bede porownywac 9 bajtow
	    repe cmpsb              ;proba dopasowania - porownanie 9 bajtow z rejestrow SI i DI
	    cmp cx,0                ;sprawdzam, czy udalo sie przejsc do konca - wtedy napisy sa rowne, czyli POWIODLO SIE PARSOWANIE! 
	    jne kontynuuj
	    
	    mov ah,0                ;nie przeskocze tej instrukcji, gdy parsowanie sie uda                
	    
	    kontynuuj:
	    add dx,9                ;skacze o 6 bajtow do nastepnej liczby
	    add al,ah               ;AL zwiekszam o flage sparsowania:
	                            ;nieudane: zwiekszam o JEDEN celem zbadania nastepnej wartosci
	                            ;udane: zwiekszam o ZERO i zostawiam dopasowana wartosc
	    ret
	 
	wypisz_skladowe:
		mov ah,09h
		lea dx,operand1
		int 21h
	
		;nowa linia
		mov ah,02h
		mov dl,0ah
		int 21h
		mov dl,0dh
		int 21h
	
		mov ah,09h
		lea dx,dzialanie
		int 21h
	
		;nowa linia
		mov ah,02h
		mov dl,0ah
		int 21h
		mov dl,0dh
		int 21h
	
		mov ah,09h
		lea dx,operand2
		int 21h
	
		;nowa linia
		mov ah,02h
		mov dl,0ah
		int 21h
		mov dl,0dh
		int 21h
		ret
	
kod1 ends

stos1 segment stack
	dw	200	dup(?)
	top1	dw	?
stos1 ends
end start