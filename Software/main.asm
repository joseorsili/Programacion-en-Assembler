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
  BCF TRISB, 0 ; RB0 como salida (ventilador)
  BCF TRISB, 1 ; RB1 como salida (calefactor)
  BCF STATUS, RP0

  ; Restaurar el estado inicial (apagar ambos dispositivos)
  BCF PORTB, 0 ; Apagar el ventilador
  BCF PORTB, 1 ; Apagar el calefactor

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
  
   ; Comparar con 24 grados Celsius (usando el valor 31 para esta explicación)
   MOVLW 0x0D ; Calibracion del sensor
   SUBWF temperatura, W ; Restar temperatura - 25 y dejar el resultado en W
   BTFSC STATUS, C ; Si el resultado es negativo, la temperatura es menor a 24 grados
   GOTO TEMPERATURA_BAJA ; Si es negativo, saltar a la rutina de calefacción
   GOTO TEMPERATURA_ALTA ; Si no es negativo, saltar a la rutina de ventilador

TEMPERATURA_BAJA
  ; Encender el calefactor (apagar el ventilador)
  BSF PORTB, 1 ; Encender calefactor
  BCF PORTB, 0 ; Apagar ventilador
  GOTO BUCLE ; Continuar en el bucle principal

TEMPERATURA_ALTA
  ; Encender el ventilador (apagar el calefactor)
  BSF PORTB, 0 ; Encender ventilador
  BCF PORTB, 1 ; Apagar calefactor
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