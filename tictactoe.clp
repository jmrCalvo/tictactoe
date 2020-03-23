; --------------------------------------------------------------------------------
; JUGADOR DE 3 en RAYA
; --------------------------------------------------------------------------------
; Version de 3 en raya clásico
; 1) Las fichas se pueden colocar libremente en cualquier posicion libre
; 2) Cuando se han colocado las 3 fichas, las jugadas consisten en desplazar una ficha propia 
;    de la posición en que se encuentra a una contigua
;
; El tablero se representará como una cuadrícula de casillas (i, j) donde:
;   FILAS    : i = {1, 2, 3}
;   COLUMNAS : j = {a, b, c}

; --------------------------------------------------------------------------------
; Hechos para representar un estado del juego
; --------------------------------------------------------------------------------
;
; Turno: representa a quien corresponde el turno (X maquina, O jugador humano)
; >> (Turno X|O)   
;
; Posicion: representa el estado de la posicion (i, j) del tablero
;   vacia                --> " "
;   ficha maquina        --> X
;   ficha jugador humano --> O
; >> (Posicion ?i ?j " "|X|O)
;
; Jugada: representa una jugada de desplazamiento de una ficha
;   X | O     --> qué ficha se desplaza
;   origen_i  --> fila origen           {1, 2, 3}
;   origen_j  --> columna origen        {a, b, c}
;   destino_i --> fila destino          {1, 2, 3}
;   destino_j --> columna destino       {a, b, c}
; >> (Juega X|O ?origen_i ?origen_j ?destino_i ?destino_j) 
;
; Conectado: representa que casillas estan conectadas, se utiliza para verificar
;   que un movimiento es correcto. Es una relacion simetrica.
; >> (Conectado 1|2|3 a|b|c horizontal|vertical|diagonal|diagonal_inversa 1|2|3 a|b|c)
; Ejemplo:
;   (Conectado 1 a horizontal 1 b) significa que las casillas (1, a) y (1, b)
;   están conectadas en dirección horizontal
;
; Fichas_sin_colocar: numero de fichas que restan por colocar, se utiliza para
;   gestionar la colocacion inicial de fichas
; >> (Fichas_sin_colocar X|O 3|2|1)
;
; Todas_fichas_en_tablero: todas las fichas de un jugador estan en el tablero
; >> (Todas_fichas_en_tablero O)

; --------------------------------------------------------------------------------
; Inicializar datos de juego
; --------------------------------------------------------------------------------

; Definicion del tablero
(deffacts Tablero
    (Conectado 1 a horizontal 1 b)
    (Conectado 1 b horizontal 1 c)
    (Conectado 2 a horizontal 2 b)
    (Conectado 2 b horizontal 2 c)
    (Conectado 3 a horizontal 3 b)
    (Conectado 3 b horizontal 3 c)
    (Conectado 1 a vertical 2 a)
    (Conectado 2 a vertical 3 a)
    (Conectado 1 b vertical 2 b)
    (Conectado 2 b vertical 3 b)
    (Conectado 1 c vertical 2 c)
    (Conectado 2 c vertical 3 c)
    (Conectado 1 a diagonal 2 b)
    (Conectado 2 b diagonal 3 c)
    (Conectado 1 c diagonal_inversa 2 b)
    (Conectado 2 b diagonal_inversa 3 a)
)

(defrule Conectado_es_simetrica
    (declare (salience 1))  ; <-- se ejecutara antes que cualquiera otra regla en la fase inicial del juego
    (Conectado ?i ?j ?forma ?i1 ?j1)
    =>
    (assert (Conectado ?i1 ?j1 ?forma ?i ?j))
)

; Estado inicial
(deffacts Estado_inicial
    (Posicion 1 a " ")
    (Posicion 1 b " ")
    (Posicion 1 c " ")
    (Posicion 2 a " ")
    (Posicion 2 b " ")
    (Posicion 2 c " ")
    (Posicion 3 a " ")
    (Posicion 3 b " ")
    (Posicion 3 c " ")
    (Fichas_sin_colocar O 3)
    (Fichas_sin_colocar X 3)
)
;;; se supone que las fichas estan en la posicion (0, 0) antes de colocarlas

; --------------------------------------------------------------------------------
; Lanzar juego
; --------------------------------------------------------------------------------
(defrule Elige_quien_comienza
    =>
    (printout t "Quien quieres que empieze: (escribre X para la maquina u O para empezar tu) ")
    (assert (Turno (read)))
)

; --------------------------------------------------------------------------------
; Mostrar tablero (solo cuando sea el turno del jugador humano)
; --------------------------------------------------------------------------------

; Detectar turno del jugador humano 
(defrule muestra_posicion_turno_jugador
    (declare (salience 10))
    (Turno O)
    =>
    (assert (muestra_posicion))
)

; Mostrar tablero
(defrule muestra_posicion
    (declare (salience 1))
    (muestra_posicion)
    (Posicion 1 a ?p11)
    (Posicion 1 b ?p12)
    (Posicion 1 c ?p13)
    (Posicion 2 a ?p21)
    (Posicion 2 b ?p22)
    (Posicion 2 c ?p23)
    (Posicion 3 a ?p31)
    (Posicion 3 b ?p32)
    (Posicion 3 c ?p33)
    =>
    (printout t crlf)
    (printout t "   a      b      c" crlf)
    (printout t "   -      -      -" crlf)
    (printout t "1 |" ?p11 "| -- |" ?p12 "| -- |" ?p13 "|" crlf)
    (printout t "   -      -      -" crlf)
    (printout t "   |  \\   |   /  |" crlf)
    (printout t "   -      -      -" crlf)
    (printout t "2 |" ?p21 "| -- |" ?p22 "| -- |" ?p23 "|" crlf)
    (printout t "   -      -      -" crlf)
    (printout t "   |   /  |  \\   |" crlf)
    (printout t "   -      -      -" crlf)
    (printout t "3 |" ?p31 "| -- |" ?p32 "| -- |" ?p33 "|"crlf)
    (printout t "   -      -      -" crlf)
)

; --------------------------------------------------------------------------------
; Juega el humano, quedan fichas por colocar
; --------------------------------------------------------------------------------
; Seleccionar donde colocar la ficha y quitar el turno
(defrule jugada_contrario_fichas_sin_colocar
    ?f <- (Turno O)
    (Fichas_sin_colocar O ?n)
    =>
    (printout t "en que posicion colocas la siguiente ficha" crlf)
    (printout t "escribe la fila (1,2 o 3): ")
    (bind ?fila (read))
    (printout t "escribe la columna (a,b o c): ")
    (bind ?columna (read))
    (assert (Juega O 0 0 ?fila ?columna))
    (retract ?f)  ; <-- quitar el turno a O
)

; Comprobar si adonde se quiere poner la ficha esta vacio
(defrule juega_contrario_fichas_sin_colocar_check
    (declare (salience 1))
    ?f <- (Juega O 0 0 ?i ?j)
    (not (Posicion ?i ?j " "))
    =>
    (printout t "No puedes jugar en " ?i ?j " porque no esta vacio" crlf)
    (retract ?f)
    (assert (Turno O))  ; <-- devolver el turno a O
)

; Actualizar estado si se ha colocado la ficha en una casilla vacia y pasar turno
(defrule juega_contrario_fichas_sin_colocar_actualiza_estado
    ?f <- (Juega O 0 0 ?i ?j)
    ?g <- (Posicion ?i ?j " ")
    =>
    (retract ?f ?g)
    (assert (Turno X)               ; <-- pasar turno
            (Posicion ?i ?j O)      ; <-- actualizar tablero 
            (reducir_fichas_sin_colocar O)) ; <-- reducir numero de fichas por colocar
)

; Reducir numero de fichas por colocar
(defrule reducir_fichas_sin_colocar
    (declare (salience 1))
    ?f <- (reducir_fichas_sin_colocar ?jugador)
    ?g <- (Fichas_sin_colocar ?jugador ?n)
    =>
    (retract ?f ?g)
    (assert (Fichas_sin_colocar ?jugador (- ?n 1)))
)

; Detectar que no quedan fichas por colocar para un jugador
(defrule todas_las_fichas_en_tablero
    (declare (salience 1))
    ?f <- (Fichas_sin_colocar ?jugador 0)
    =>
    (retract ?f)
    (assert (Todas_fichas_en_tablero ?jugador))
)

; --------------------------------------------------------------------------------
; Juega el humano, todas las fichas en tablero
; --------------------------------------------------------------------------------
; Seleccionar movimiento
(defrule juega_contrario
    ?f <- (Turno O)
    (Todas_fichas_en_tablero O)
    =>
    (printout t "en que posicion esta la ficha que quieres mover?" crlf)
    (printout t "escribe la fila (1,2,o 3): ")
    (bind ?origen_i (read))
    (printout t "escribe la columna (a,b o c): ")
    (bind ?origen_j (read))
    (printout t "a que posicion la quieres mover?" crlf)
    (printout t "escribe la fila (1,2,o 3): ")
    (bind ?destino_i (read))
    (printout t "escribe la columna (a,b o c): ")
    (bind ?destino_j (read))
    (assert (Juega O ?origen_i ?origen_j ?destino_i ?destino_j))
    (printout t "Juegas mover la ficha de "  ?origen_i ?origen_j " a " ?destino_i ?destino_j crlf)
    (retract ?f)  ; <-- quitar el turno a O
)

; Comprobar si la ficha que se mueve es una de jugador humano O
(defrule juega_contrario_check_mueve_ficha_propia
    (declare (salience 1))
    ?f <- (Juega O ?origen_i ?origen_j ?destino_i ?destino_j)
    (Posicion ?origen_i ?origen_j ?X)
    (test (neq O ?X)) ; <-- ficha a mover no es ficha O
    =>
    (printout t "No es jugada valida porque en " ?origen_i ?origen_j " no hay una ficha tuya" crlf)
    (retract ?f)
    (assert (Turno O)) ; <-- devolver el turno a O
)

; Comprobar si la posicion a la que se mueve esta vacia
(defrule juega_contrario_check_mueve_a_posicion_libre
    (declare (salience 1))
    ?f <- (Juega O ?origen_i ?origen_j ?destino_i ?destino_j)
    (Posicion ?destino_i ?destino_j ?X)
    (test (neq " " ?X)) ; <-- posicion destino no vacia
    =>
    (printout t "No es jugada valida porque " ?destino_i ?destino_j " no esta libre" crlf)
    (retract ?f)
    (assert (Turno O)) ; <-- devolver el turno a O
)

; Comprobar si la posicion a la que se mueve esta conectada
(defrule juega_contrario_check_conectado
    (declare (salience 1))
    (Todas_fichas_en_tablero O)
    ?f <- (Juega O ?origen_i ?origen_j ?destino_i ?destino_j)
    (not (Conectado ?origen_i ?origen_j ? ?destino_i ?destino_j))  ; <-- posicion destino no conectada con origen
    =>
    (printout t "No es jugada valida porque "  ?origen_i ?origen_j " no esta conectado con " ?destino_i ?destino_j crlf)
    (retract ?f)
    (assert (Turno O)) ; <-- devolver el turno a O
)

; Actualizar estado si se ha colocado la ficha en una casilla vacia y pasar turno
(defrule juega_contrario_actualiza_estado
    ?f <- (Juega O ?origen_i ?origen_j ?destino_i ?destino_j)
    ?h <- (Posicion ?origen_i ?origen_j O)
    ?g <- (Posicion ?destino_i ?destino_j " ")
    =>
    (retract ?f ?g ?h)
    (assert (Turno X) ; <-- pasar turno
            (Posicion ?destino_i ?destino_j O)     ; <-- actualizar tablero 
            (Posicion ?origen_i ?origen_j " ") )   ; <-- actualizar tablero 
)

; --------------------------------------------------------------------------------
; Juega la maquina, quedan fichas por colocar
; --------------------------------------------------------------------------------

;;;;;;;;; SIN CRITERIO ;;;;;;;;;
(defrule clisp_juega_sin_criterio_fichas_sin_colocar
    (declare (salience -9999))
    ?f <- (Turno X)
    (Fichas_sin_colocar X ?n)
    ?g <- (Posicion ?i ?j " ") ; <-- toma una posicion del tablero vacia, sin ningun criterio (la primera que haga 'match')
    =>
    (printout t "Juego poner ficha en " ?i ?j crlf)
    (retract ?f ?g)
    (assert (Posicion ?i ?j X) ; <-- actualizar tablero 
            (Turno O) 
            (reducir_fichas_sin_colocar X))
)

;;; EXTENDER PARA GENERAR UNA JUGADA BAJO ALGUN CRITERIO
;;; Directamente: (assert (Posicion ?i ?j X))
;;; Mediante jugada: (assert (Juega X ?origen_i ?origen_j ?destino_i ?destino_j))

; --------------------------------------------------------------------------------
; Juega la maquina, todas las fichas en tablero
; --------------------------------------------------------------------------------

;;;;;;;;; SIN CRITERIO ;;;;;;;;;
(defrule clisp_juega_sin_criterio
    (declare (salience -9999))
    ?f <- (Turno X)
    (Todas_fichas_en_tablero X)
    (Posicion ?origen_i ?origen_j X)        ; <-- toma una posicion del tablero con X, sin ningun criterio (la primera que haga 'match')
    (Posicion ?destino_i ?destino_j " ")    ; <-- toma una posicion del tablero vacia, sin ningun criterio (la primera que haga 'match')
    (Conectado ?origen_i ?origen_j ? ?destino_i ?destino_j) ; <-- se asegura de que este conectada
    =>
    (assert (Juega X ?origen_i ?origen_j ?destino_i ?destino_j))
    (printout t "Juego mover la ficha de "  ?origen_i ?origen_j " a " ?destino_i ?destino_j crlf)
    (retract ?f)
)

;;; EXTENDER PARA GENERAR UNA JUGADA BAJO ALGUN CRITERIO
;;; Mediante jugada: (assert (Juega X ?origen_i ?origen_j ?destino_i ?destino_j))

; Actualizar estado si se ha seleccionado una X y colocado la ficha en una casilla vacia, y pasar turno
(defrule juega_clisp_actualiza_estado
    ?f <- (Juega X ?origen_i ?origen_j ?destino_i ?destino_j)
    ?h <- (Posicion ?origen_i ?origen_j X) ; <-- con el cogido actual no seria necesario comprobarlo
    ?g <- (Posicion ?destino_i ?destino_j " ")
    =>
    (retract ?f ?g ?h)
    (assert (Turno O)  ; <-- pasar turno a X
            (Posicion ?destino_i ?destino_j X) 
            (Posicion ?origen_i ?origen_j " ") )
)

; --------------------------------------------------------------------------------
; FIN DE JUEGO
; --------------------------------------------------------------------------------
(defrule tres_en_raya
    (declare (salience 9999))

    ; turno de cualquier jugador
    ?f <- (Turno ?X)

    ; recuperar posiciones [1, 2, 3] de fichas de uno de los jugadores
    (Posicion ?i1 ?j1 ?jugador)
    (Posicion ?i2 ?j2 ?jugador)
    (Posicion ?i3 ?j3 ?jugador)

    ; las posiciones estan conectadas [1 con 2, 2 con 3]
    (Conectado ?i1 ?j1 ?forma ?i2 ?j2)
    (Conectado ?i2 ?j2 ?forma ?i3 ?j3)

    ; ninguna de las posiciones esta vacia
    (test (neq ?jugador " "))

    ; evitar que se tome dos veces la misma casilla en la comprobacion
    (test (or (neq ?i1 ?i3) (neq ?j1 ?j3)))
    
    =>
    (printout t ?jugador " ha ganado pues tiene tres en raya " ?i1 ?j1 " " ?i2 ?j2 " " ?i3 ?j3 crlf)
    (retract ?f)
    (assert (muestra_posicion))
) 

