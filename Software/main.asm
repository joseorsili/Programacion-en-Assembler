;====================================================================
; DEFINICIONES
;====================================================================
#include p16f688.inc ; Incluir el archivo de definición de registros
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
RST   code  0x0
    goto Start

;====================================================================
; SEGMENTO DE CÓDIGO
;====================================================================
Start
    ; Configurar pines (RC0: motor, RC1: calefactor, RC3-RC5: switches)
    BSF STATUS, RP0
    BCF TRISC, 0 ; RC0 como salida (motor)
    BCF TRISC, 1 ; RC1 como salida (calefactor)
    BSF TRISC, 2 ; RC2 como entrada digital
    BSF TRISC, 3 ; RC3 como entrada (switch)
    BSF TRISC, 4 ; RC4 como entrada (switch)
    BSF TRISC, 5 ; RC5 como entrada (switch)
    ; Configurar RC2 como entrada digital
    BCF STATUS, RP0

    ; Restaurar el estado inicial (apagar ambos dispositivos)
    BCF PORTC, 0 ; Apagar el motor
    BCF PORTC, 1 ; Apagar el calefactor
    
    ; Configurar RA0 como entrada analógica para el sensor LM35
    BSF ANSEL, 0 ; Configurar RA0/AN0 como entrada analógica
    BCF TRISA, 0 ; RA0 como entrada digital

    ; Desactivar el módulo A/D para configurarlo
    BCF ADCON0, ADON

BUCLE
    ; Encender el módulo A/D
    BSF ADCON0, ADON

    ; Llamar a la subrutina para leer el sensor LM35
    CALL ReadLM35

    ; Leer el estado de los switches en RC3, RC4 y RC5
    ;GOTO NADA
    BTFSC PORTC, 3 ; Verificar RC3
    GOTO SWITCH_RC3_ON
    BTFSC PORTC, 4 ; Verificar RC4
    GOTO SWITCH_RC4_ON
    BTFSC PORTC, 5 ; Verificar RC5
    GOTO SWITCH_RC5_ON
    ; Código para cuando RC3 está activado
    MOVLW 0x07 ; Cambio de temperatura en 14 grados
    GOTO TEMPERATURA_SW
    
TEMPERATURA_SW
    SUBWF temperatura, W ; Restar temperatura - 25 y dejar el resultado en W
    BTFSS STATUS, C ; Si el resultado es positivo (temperatura mayor a 24 grados), saltar
    GOTO TEMPERATURA_ALTA ; Si es positivo, ir a la rutina de ventilador
    GOTO TEMPERATURA_BAJA ; Si no es positivo, ir a la rutina de calefacción
    GOTO BUCLE
    
SWITCH_RC3_ON
    ; Código para cuando RC3 está activado
    MOVLW 0x0B ; Cambio de temperatura en 14 grados
    GOTO TEMPERATURA_SW

SWITCH_RC4_ON
    ; Código para cuando RC4 está activado
    ; Temperatura estándar (24 grados)
    MOVLW 0x0D ; Calibración del sensor
    GOTO TEMPERATURA_SW

SWITCH_RC5_ON
    ; Código para cuando RC5 está activado
    MOVLW 0x0E ; Cambio de temperatura en 27 grados
    GOTO TEMPERATURA_SW 
    
TEMPERATURA_BAJA
    ; Encender el calefactor (apagar el motor)
    BSF PORTC, 1 ; Encender calefactor
    GOTO BUCLE ; Continuar en el bucle principal

TEMPERATURA_ALTA
    ; Encender el motor (apagar el calefactor)
    BSF PORTC, 0 ; Encender motor
    GOTO BUCLE ; Continuar en el bucle principal
    
ReadLM35
    ; Leer LM35 conectado a RA0
    BSF ADCON0, GO ; Iniciar la conversión A/D

WAIT_FOR_ADC
    ; Esperar hasta que la conversión A/D esté completa
    BTFSC ADCON0, GO_DONE
    GOTO WAIT_FOR_ADC

    ; En este punto, la conversión A/D está completa, podemos obtener la temperatura
    MOVF ADRESH, W ; Mover el valor de ADRESH a W
    MOVWF temperatura ; Almacenar el valor en la variable temperatura
    RETURN
    
NADA
    RETURN    

DELAY
  ; Retardo simple
  MOVLW 0xFF
  MOVWF COUNT1
  
COUNT1 EQU 0x30
COUNT2 EQU 0x31  
;====================================================================
END