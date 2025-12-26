CONTEXT: Ho necessità di creare un sprite in pixel art , preciso, divisibile in colonna 
le dimensioni del file devono rispettare un incolonnamento di dimensione 32*32 
quindi se nello sprite inseriamo massimo 8 frame per riga la dimensione di ogni frame sarà 32*32 
e considerando anche un spazio laterale disponibile vuoto il file al minimo deve essere grande 
8*32  + 2*32 per il valore orizzontale 
mentre per il valore verticale deve essere 
N*32 + 2*32 dove N corrisponde al numero di animazioni che dobbiamo creare. 

Dato questo contesto prendi questa immagine che ti dò e applica queste regole per tramutare l'immagine in una miniatura pixel art con questi frame che necessito per creare le animazioni tramite il AnimatedSprite ( per questo bisogna che siano precise come dimensioni e siano correttamente incolonnate

Le Animazioni devono essere : 

1) Idle: Movimento su e giù con qualche movimento di braccia
2) Run: Movimento di corsa con in avanti 
3) Jump: Movimento di salto verso alto con apertura delle gambe 
4) Dash: Movimento di slancio in avanti con scia disegnata 
5) Attack: movimento di lancio del cappellino ( quindi considerare sprite senza cappellino ) 

come detto prima essendo 5 animazioni il calcolo del foglio finale rispetterà 

8*32 + 2*32 per le colonne 
5*32 + 2*32 per le righe ( nota bene 5 sono il numero di animazioni ) 

