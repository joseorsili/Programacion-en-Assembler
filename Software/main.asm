;====================================================================
; DEFINICIONES
;====================================================================

#include p16f877a.inc                ; Incluir el archivo de definición de registros

;====================================================================
; VARIABLES
;====================================================================
CBLOCK 0x20
    valor1
    valor
    ASCII_H
    ASCII_M
    ASCII_L
    temperatura ; Variable para almacenar la lectura del sensor LM35
ENDC
;====================================================================
; VECTORES DE RESET E INTERRUPCIÓN
;====================================================================
      ; Vector de reinicio
RST   code  0x0 
      goto  Start
;====================================================================
; SEGMENTO DE CÓDIGO
;====================================================================
Start
  BSF STATUS, RP0
  BCF TRISB, 0 ; RB0 como salida (LED 1)
  BCF STATUS, RP0

  ; Configurar ADC
  BSF ADCON1, PCFG0 ; Configurar RA0/AN0 como entrada analógica (0000 para AN0)
  BCF ADCON1, PCFG1
  BCF ADCON1, PCFG2
  BCF ADCON1, PCFG3
  BCF ADCON0, ADON  ; Desactivar el módulo A/D para configurarlo

BUCLE
  ; Encender el módulo A/D
  BSF ADCON0, ADON

  ; Llamar a la subrutina para leer el sensor LM35
  CALL ReadLM35

  ; Comparar con un valor fijo (para pruebas)
  MOVLW 0x80 ; Comparar con 128 (valor intermedio para un ADC de 10 bits)
  SUBWF ADRESH, W ; Restar ADRESH - 128 y dejar el resultado en W
  BTFSS STATUS, Z ; Si el resultado es cero, saltar
  GOTO SUPERA_TEMP ; Si no es cero, saltar

  ; Encender el LED 1
  BSF PORTB, 0
  GOTO BUCLE ; Continuar en el bucle principal

SUPERA_TEMP
  ; Apagar el LED 1
  BCF PORTB, 0

  GOTO BUCLE ; Continuar en el bucle principal

; Subrutina para leer el sensor LM35
ReadLM35
  ; Leer LM3 conectado a RA0
  BSF ADCON0, GO ; Iniciar la conversión A/D

WAIT_FOR_ADC
  ; Esperar hasta que la conversión A/D esté completa
  BTFSC ADCON0, GO_DONE
  GOTO WAIT_FOR_ADC

  ; En este punto, la conversión A/D está completa, podemos obtener la temperatura
  MOVF ADRESH, W ; Mover el valor de ADRESH a W
  MOVWF temperatura ; Almacenar el valor en la variable temperatura
  RETURN

DELAY
  ; Retardo simple
  MOVLW 0xFF
  MOVWF COUNT1
LOOP1
  MOVLW 0xFF
  MOVWF COUNT2
LOOP2
  DECFSZ COUNT2, F
  GOTO LOOP2
  DECFSZ COUNT1, F
  GOTO LOOP1
  RETURN

COUNT1 EQU 0x30
COUNT2 EQU 0x31

;====================================================================
      END