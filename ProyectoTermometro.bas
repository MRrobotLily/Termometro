#picaxe 20X2          ; Define el microcontrolador PICAXE 20X2
setfreq m16           ; Configura la frecuencia del micro a 16 MHz

symbol lcentigrados = w0   ; Variable palabra para temperatura en ?C
symbol lfahrenheit  = w1   ; Variable palabra para temperatura en ?F
symbol lTemp        = w2   ; Variable para lectura cruda del ADC
symbol tem          = w3   ; Variable temporal para mostrar temperatura
symbol suma         = w4   ; Acumulador para promediar lecturas
symbol promedio     = w5   ; Resultado del promedio

symbol decenas      = b12  ; D?gito de las decenas
symbol unidades     = b13  ; D?gito de las unidades
symbol refresco     = b14  ; Contador para multiplexado de displays
symbol modo         = b15  ; 0 = ?C, 1 = ?F
symbol i            = b16  ; Contador del bucle
symbol lectura1     = b17  ; Primera lectura del bot?n
symbol lectura2     = b18  ; Segunda lectura (antirrebote)
symbol digito       = b19  ; D?gito actual a mostrar

symbol disp1        = C.1  ; Pin del display 1 (decenas)
symbol disp2        = C.2  ; Pin del display 2 (unidades)
symbol disp3        = C.3  ; Pin del display 3 (C o F)
symbol ledC         = C.4  ; LED indicador de ?C
symbol ledF         = C.5  ; LED indicador de ?F

init:
    dirsB = %11111111     ; Puerto B como salida (segmentos display)
    dirsC = %00111110     ; Configura pines C (displays y LEDs como salida)

    low disp1             ; Apaga display 1
    low disp2             ; Apaga display 2
    low disp3             ; Apaga display 3
    low ledC              ; Apaga LED ?C
    low ledF              ; Apaga LED ?F
    let pinsB = %00000000 ; Apaga todos los segmentos
    modo = 0              ; Inicia en modo Celsius

main:

    suma = 0              ; Reinicia acumulador
    for i = 1 to 10       ; Toma 10 muestras
        readadc10 C.7, lTemp  ; Lee ADC de 10 bits en pin C.7
        suma = suma + lTemp   ; Acumula lectura
        pause 2               ; Peque?o retardo
    next i
    promedio = suma / 10  ; Calcula promedio

    lcentigrados = promedio * 50 / 102 ; Convierte a ?C (sensor tipo LM35)

    lectura1 = pinC.6     ; Lee estado del bot?n
    pause 20              ; Espera (antirrebote)
    lectura2 = pinC.6     ; Segunda lectura

    if lectura1 = lectura2 then  ; Verifica lectura estable
        if lectura1 = 1 then
            modo = 1             ; Cambia a Fahrenheit
        else
            modo = 0             ; Mantiene Celsius
        endif
    endif

    if modo = 0 then      ; Si est? en Celsius
        tem = lcentigrados ; Usa temperatura en ?C

        if lcentigrados >= 30 then ; Si supera 30?C
            high ledC      ; Enciende LED ?C
        else
            low ledC       ; Apaga LED ?C
        endif

        low ledF           ; Apaga LED ?F
    else
        lfahrenheit = lcentigrados * 9 / 5 + 32 ; Convierte a ?F
        tem = lfahrenheit  ; Usa temperatura en ?F

        if lfahrenheit >= 86 then ; Si supera 86?F (~30?C)
            high ledF      ; Enciende LED ?F
        else
            low ledF       ; Apaga LED ?F
        endif

        low ledC           ; Apaga LED ?C
    endif

    if tem > 99 then       ; Limita a dos d?gitos
        tem = 99
    endif

    decenas = tem / 10     ; Obtiene decenas
    unidades = tem // 10   ; Obtiene unidades

    for refresco = 1 to 150 ; Multiplexado de displays

        gosub apagar_displays ; Apaga todos
        digito = decenas      ; Carga decenas
        gosub display         ; Muestra n?mero
        high disp1            ; Activa display 1
        pause 1
        low disp1             ; Apaga display 1

        gosub apagar_displays
        digito = unidades     ; Carga unidades
        gosub display
        high disp2            ; Activa display 2
        pause 1
        low disp2

        gosub apagar_displays
        if modo = 0 then
            gosub letra_c     ; Muestra "C"
        else
            gosub letra_f     ; Muestra "F"
        endif
        high disp3            ; Activa display 3
        pause 1
        low disp3

    next refresco

goto main                  ; Repite ciclo infinito


apagar_displays:
    low disp1              ; Apaga display 1
    low disp2              ; Apaga display 2
    low disp3              ; Apaga display 3
    let pinsB = %00000000  ; Apaga segmentos
return


display:
    if digito = 0 then gosub numero0
    if digito = 1 then gosub numero1
    if digito = 2 then gosub numero2
    if digito = 3 then gosub numero3
    if digito = 4 then gosub numero4
    if digito = 5 then gosub numero5
    if digito = 6 then gosub numero6
    if digito = 7 then gosub numero7
    if digito = 8 then gosub numero8
    if digito = 9 then gosub numero9
return


numero0: let pinsB = %00111111 : return ; Patr?n para 0
numero1: let pinsB = %00000110 : return ; Patr?n para 1
numero2: let pinsB = %01011011 : return ; Patr?n para 2
numero3: let pinsB = %01001111 : return ; Patr?n para 3
numero4: let pinsB = %01100110 : return ; Patr?n para 4
numero5: let pinsB = %01101101 : return ; Patr?n para 5
numero6: let pinsB = %01111101 : return ; Patr?n para 6
numero7: let pinsB = %00000111 : return ; Patr?n para 7
numero8: let pinsB = %01111111 : return ; Patr?n para 8
numero9: let pinsB = %01101111 : return ; Patr?n para 9

letra_c: let pinsB = %00111001 : return ; Patr?n letra C
letra_f: let pinsB = %01110001 : return ; Patr?n letra F