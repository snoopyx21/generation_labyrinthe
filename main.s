###############################################
#					      #   
#					      #
#		DIVRIOTIS Constantin 	      #
#					      #
#		VETRIVEL Govindaraj	      #
#       PROJET ARCHITECTURE DES ORDINATEURS   #
#					      #
###############################################

.data

saisie: 	.asciiz "Entrez un entier: "
Tableau: 	.asciiz "Tableau de taille: "
affichage: 	.asciiz "Votre entier est: "
espace: 	.asciiz " "
RetChar: 	.asciiz "\n"
file: 		.asciiz "generation.txt"
buffer:  	.space  5000
str_data_end: 	.asciiz ""
seed: 		.word   0xfaceb00c, 0xdeadbeef
max_float_alea: .float 2147483647
BUFFER:      	.word   128                           # Taille des buffers
ERROPEN:  	.asciiz "Erreur lors de l'ouverture du fichier.\n"
ERRREAD:    	.asciiz "Erreur lors de la lecture du fichier.\n"
DEMANDE:    	.asciiz "Veuillez entrer le nom du ficher dans lequel il y a le labyrinthe :\n"
Choix:          .asciiz "Entrer:\n  0 si vous voulez generer un labyrinthe\n  1 pour resoudre un labyrinthe\n"

.text
.globl __start

__start:
#######################
########################
######### MAIN

la  $a0  Choix 		# adresse chaine  à afficher
li  $v0  4 		# afficher la chaine
syscall 
li  $v0  5 		# appel système de lecture d'un entier
syscall 
beq  $v0  0  Generer

######################## Debut Resoudre
Resoudre:
    # Demande du fichier.
    la  $a0  DEMANDE
    jal AfficherString


    # Lecture du fichier.
    li  $a0  128  
    jal Entree

    # Traitement du fichier (suppression de '\n' superflus).
    move $a0  $v0
    jal ChercheBSlashN

    
    move $a0  $v0
    move $s7  $a0
    jal AfficherString

    # Lecture du labyrinthe en ascii et permet d'inserer les valeurs lus dans un tableau
    jal Tab_valeur
    move  $s5  $a0
    move  $s6  $a1
    
    # On recupere la case de depart
    jal TrouveCaseDepart
    move  $a2  $v0
    
    # On resout le labyrinthe
    jal  Resolution
    move  $a2  $a1
    move  $a1  $a0
    mul   $a0  $a2  $a2 
    move  $s1  $a1
    move  $s2  $a2
    move  $s0  $a0
    li    $s3  0
    
    # on enleve la valeur 128 (2 puissance 7) -> bit utlise pour la generation
    M2128:
		bgt  $s3 $a0 FinM2128
		lw   $t0  0($a1)
		bgt  $t0  128  Moins128
		j    PasMoins128
	Moins128:
		subi $t0  $t0  128
	PasMoins128:
		sw   $t0  0($a1)
		addi $s3  $s3  1
		addi $a1  $a1  4
		j    M2128
	FinM2128:
    move  $a1  $s1
    move  $s6  $a0
    move  $a0  $s7
    jal   RajouteResolu
    move  $s7  $v0
    move  $a0  $s6
    # On ecrit dans un nouveau fichier -> ****.txt.resolu
    jal   Tab_ascii		
    li    $a3   0
    jal   Ecriture_Fichier 
    j     Exit
########################Fin Resoudre


########################Debut Generation
Generer:
	la    $a0  saisie 	# adresse chaine  à afficher
	li    $v0  4 		# afficher la chaine
	syscall 
	li    $v0  5 		# appel système de lecture d'un entier
	syscall 
	move  $a2  $v0 
	move  $s5  $a2		# N dans $s5
	mul   $a0  $a2  $a2 
	move  $s6  $a0		# N*N dans $s6
	move  $a1  $a0 
	la    $a0  affichage
	li    $v0  4
	syscall
	move  $a0  $a1
	li    $v0  1
	syscall
	move  $t0  $a0
	la    $a0  RetChar
	li    $v0  4
	syscall
	move  $a0  $t0		# affichage test

	jal CreerTableau
	move  $s7  $v0
	move  $a1  $s7		# creation du tableau
				# adresse du debut du tableau dans $s7
	jal InitTableau		# initialisation des murs
				# valeurs 0 à l'interieur du labyrinthe

	move  $a1  $s7
	jal   Case_depart_arrive# initialisation de la valeur de la case de depart et d'arrivé
	move  $s4  $v1
	
	
	move  $a1  $s7
	move  $a0  $s6
	move  $a2  $s5
	move  $a3  $s4
	
	
	jal GenFinal
	
	move  $a1  $s7
	move  $a0  $s6
	move  $a2  $s5
	li $s1  0
	M128:
		bgt  $s1 $a0 FinM128
		lw   $t0  0($a1)
		subi $t0  $t0  128
		sw   $t0  0($a1)
		addi $s1  $s1  1
		addi $a1  $a1  4
		j  M128
	
	FinM128:
	
	
	move  $a1  $s7
	move  $a0  $s6
	move  $a2  $s5

	jal   Tab_ascii		# convertir les chiffres en carctères afin de les inserer dans le tableau
	move  $a1  $s7
	move  $a0  $s6
	move  $a2  $s5
	li    $a3  1
	jal   Ecriture_Fichier 	# (dans aftab)
	j     Exit
######################## Fin Generer


Exit:
	li    $v0  10    	 # appel système 10: fin du programme
	syscall


######################### Fin Main 
##################################
#################################



#######################
#######################
######### FONCTIONS {{{


########################Debut GenFinal : fonction principal de generation
#argument= ceux renvoyer par Case_Depart_Arrivee puis recursive:  $a1:  adresse debut tab, $a2: taille tab, $a3: offsetcase depart 
GenFinal:
subu  $sp  $sp  36
sw    $a0  32($sp)
sw    $a1  28($sp)
sw    $a2  24($sp)
sw    $s0  20($sp) 
sw    $s1  16($sp)
sw    $s2  12($sp)
sw    $s3  8($sp)
sw    $s4  4($sp)
sw    $ra  0($sp)

	move  $s0  $a1
	move  $s1  $a2
	
	move  $a1  $a3
	li    $a2  -1
	#Dans le pile on rajoute l'adresse de debut de tableau, l'offset de  debut , l'offset de la case courante et l'offset de la case precedente
	#pour le premier offset de la case precedente  pour la case de depart on prend -1 étant donnee que c'est la premiere
	sub   $sp  $sp  12
	sw    $s0  0($sp)
	sh    $a1  4($sp)
	sh    $a3  6($sp)
	sw    $a2  8($sp)
	
	add   $t0  $s0  $a3
	lw    $t1  0($t0) ## on marque la case de d�part comme visit�: +128
	addi  $t1  $t1  128
	sw    $t1  0($t0)   
	
	
	Chemin:
		lh    $s2  6($sp)
		lh    $s3  4($sp)
		lw    $s0  0($sp)
		beq   $s3  $s2  CondCaseDepart
		add   $t0  $s0  $s2
		lw    $t1  0($t0)
		bgt   $t1  127  Visitee  
		addi  $t1  $t1  128
		sw    $t1  0($t0)
		subu  $t1  $t1  128
		bgt   $t1  32   CasFin #si on est ?a case de fin on revient ainsi il n'ya plus de chemain apres la case de fin
		Visitee:
			jal   TrouveVoisinNV # renvoie l'offset de la case suivante($v0) si il y en a une non visitee
					     # ainsi qu'un chiffre entre 0 et 3 pour la direction du mur : haut,bas, droite, gauche
					     # 0 => haut
					     # 1 => droite
					     # 2 => bas
					     # 3 => gauche
			beq   $v0  $s2  RetourArriere
			move  $s4  $v1
			sub   $sp  $sp  12
			sw    $s0  0($sp)
			sh    $s3  4($sp)	
			sh    $v0  6($sp)
			sw    $s2  8($sp)
			move  $a1  $s4
			jal   Detruit_mur
			j     Chemin
	CasFin:
	RetourArriere:
		addi  $sp  $sp  12
		j     Chemin
	
	# conditions de case de depart donnes dans l'alogrithme
	CondCaseDepart:
		jal   TrouveVoisinNV
		beq   $v0  $s2   Fin_GenFinal
		move  $s4  $v1
		subu  $sp  $sp  12
		sw    $s0  0($sp)
		sh    $s3  4($sp)	
		sh    $v0  6($sp)
		sw    $s2  8($sp)
		move  $a1  $s4
		jal   Detruit_mur
		j     Chemin


Fin_GenFinal:

addu  $sp  $sp  12
lw    $a0  32($sp)
lw    $a1  28($sp)
lw    $a2  24($sp)
lw    $s0  20($sp) 
lw    $s1  16($sp)
lw    $s2  12($sp)
lw    $s3  8($sp)
lw    $s4  4($sp)
lw    $ra  0($sp)
addu  $sp  $sp  36
jr    $ra	
########################Fin_GenFinal

########################Debut TrouveVoisinNV
# on cherche des voisins non visites
TrouveVoisinNV:
	subu  $sp  $sp  44
	sw    $a0  40($sp)
	sw    $a1  36($sp)
	sw    $a2  32($sp)
	sw    $s0  28($sp) 
	sw    $s1  24($sp)
	sw    $s2  20($sp)
	sw    $s3  16($sp)
	sw    $s4  12($sp)
	sw    $s5  8($sp)
	sw    $s6  4($sp)
	sw    $ra  0($sp)
	
	move  $s2  $s1  	## on sauvegarde la taille n dans $s2 
	lw    $s0  44($sp) 	## on sauvegarde l'addrese de debut de tableau dans $s0
	lh    $s1  50($sp) 	## on sauvegarde l'offset de la case courante dansl $s1
	
	
	beq   $s1  0    Angle_GH ##si l'offset est �gale � 0 la case est dans l'angle en haut � gauche
	
	li    $t1  4
	mul   $t0  $s2  $s2 	## n*n
	mul   $t0  $t0  $t1  	## n*n*4
	sub   $t0  $t0  $t1  	##n*n*4 -4
	beq   $s1  $t0  Angle_DB##si l'offset est �gale � (n*n)*4-4 la case est dans l'angle en bas � droite
	
	
	move  $t2  $s2  	 #n
	mul   $t0  $t2  $t1 	 #n*4
	mul   $t2  $t2  $t0 	 #n*(n*4)
	sub   $t2  $t2  $t0 	 #n*n*4  -  n*4
	beq   $s1  $t2  Angle_GB #si l'offset est �gale � (n*n*4)-(n*4) la case est dans l'angle en bas � gauche
	
	li    $t1  4
	mul   $t0  $s2  $t1 	 # n*4
	sub   $t0  $t0  $t1 	 # n*4 -4
	beq   $s1  $t0  Angle_DH #si l'offset est �gale � n*4 -4 la case est dans l'angle en bas � droite
	
	
	add   $t0  $t0  $t1 	 #n*4
	blt   $s1  $t0  Ligne_H  #regarde si l'offset est inferieur a n*4 et donc sur la 1ere ligne
	

	move  $t0  $s2
	li    $s6  0
	li    $t1  4
	mul   $t3  $t0  $t1 	# n*4
	sub   $t2  $t3  $t1 	# n*4-4
	move  $s5  $t2
	
	
	Debut_Test_LD:
		      beq   $s6  $t0  Test_LG  ### teste si l'offset est sur la ligne de droite sinon renvoie vers le test de la ligne de gauche
		      beq   $s5  $s1  Ligne_D
		      addi  $s6  $s6  1
		      add   $s5  $s5  $t3
		      j     Debut_Test_LD

		
	
	Test_LG:	
		move  $t0  $s2
		li    $s6  0
		li    $t1  4
		mul   $t3  $t0  $t1 	#n*4
		li    $s5  0
	Debut_Test_LG: 
		beq  $s6  $t0  Test_LB  ### teste si l'offset est sur la ligne de gauche sinon renvoie vers le test de la ligne du bas
	 	beq  $s5  $s1  Ligne_G
		addi $s6  $s6  1
		add  $s5  $s5  $t3
		j    Debut_Test_LG
		      
	
	Test_LB:
		li    $t1  4
		mul   $t0  $s2  $s2 	##n*n
		mul   $t0  $t0  $t1 	## n*n*4
		mul   $t1  $s2  $t1 	#n*4
		sub   $s5  $t0  $t1 	#n*n*4  -  n*4
	Debut_Test_LB:
		beq   $s5  $t0  CS_Cas_Base  ### teste si l'offset est sur la ligne du bas sinon renvoie vers le cas de base avec la case n'etant pas au bord
		beq   $s5  $s1  Ligne_B
		addi  $s5  $s5  4
		j     Debut_Test_LB
	
	
	
	
	CS_Cas_Base:
		li    $a1  4
		jal Aleatoire
		# 0 => haut
		# 1 => droite
		# 2 => bas
		# 3 => gauche
		move  $s6  $a0
		li    $s5  0
		Debut_recherche:
			beq   $s5  $a1  PasVoisinNV
			beq   $s6  0	Cas_0
			beq   $s6  1    Cas_1
			beq   $s6  2    Cas_2
			beq   $s6  3    Cas_3
			beq   $s6  4    Cas_Sub
		Cas_Sub:
			subi  $s6  $s6  4
			j     Debut_recherche
		Cas_0:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_H
			j     DB_Suiv
			Vers_H:
				sub   $s4  $s4  $s0
				move  $v0  $s4
				li    $v1  0
				j     FinTVNV
		Cas_1:  move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_D
			j     DB_Suiv	
			Vers_D:
				sub   $s4  $s4  $s0
				move  $v0  $s4
				li    $v1  1
				j     FinTVNV
		Cas_2:  move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   Vers_B
			j     DB_Suiv
			Vers_B:
				sub   $s4  $s4  $s0
				move  $v0  $s4
				li    $v1  2
				j     FinTVNV
		Cas_3:  move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  #offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  Vers_G
		        j     DB_Suiv
		        Vers_G:
		        	sub   $s4  $s4  $s0
				move  $v0  $s4
				li    $v1  3
				j     FinTVNV
		DB_Suiv:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Debut_recherche
	
	
	Angle_GH:
		li    $a1  2
		jal   Aleatoire
		move  $s6  $a0
		li    $s5  0
		Debut_recherche_GH:
			beq   $s5  2    PasVoisinNV
			beq   $s6  0    Cas_GH_0 	# droite
			beq   $s6  1    Cas_GH_1	# en bas
			beq   $s6  2    Cas_GH_Sub
		Cas_GH_Sub: 
			subi  $s6  $s6  2
			j Debut_recherche_GH
		Cas_GH_0:
			move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_D
			j     DB_GH_Suiv
		Cas_GH_1:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   Vers_B
			j     DB_GH_Suiv
		DB_GH_Suiv:       
			addi  $s6  $s6  1
			addi  $s5  $s5  1
			j Debut_recherche_GH
	

	
	Angle_DH:
		li    $a1  2
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Debut_recherche_DH:
			beq   $s5  2    PasVoisinNV
			beq   $s6  0    Cas_DH_0	# gauche
			beq   $s6  1    Cas_DH_1	# bas
			beq   $s6  2    Cas_DH_Sub
		Cas_DH_Sub:
			subi  $s6  $s6  2
			j Debut_recherche_DH	
		Cas_DH_0:
			move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  Vers_G
			j     DB_DH_Suiv
		Cas_DH_1:	
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1	 #n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   Vers_B
			j     DB_DH_Suiv	
		DB_DH_Suiv:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Debut_recherche_DH	
		
			
				
	Angle_DB:
		li    $a1  2
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Debut_recherche_DB:
			beq   $s5  2    PasVoisinNV
			beq   $s6  0    Cas_DB_0	#gauche
			beq   $s6  1    Cas_DB_1	#haut
			beq   $s6  2    Cas_DB_Sub
		Cas_DB_Sub:
			subi  $s6  $s6  2
			j Debut_recherche_DB
		Cas_DB_0:				
			move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1 	 #offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  Vers_G				
			j     DB_DB_Suiv
		Cas_DB_1:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_H	
			j     DB_DB_Suiv						
		DB_DB_Suiv:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Debut_recherche_DB								

								
	Angle_GB:
		li    $a1  2
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Debut_recherche_GB:
			beq   $s5  2    PasVoisinNV
			beq   $s6  0    Cas_GB_0	#droite
			beq   $s6  1    Cas_GB_1	#haut
			beq   $s6  2    Cas_GB_Sub
		Cas_GB_Sub:
			subi  $s6  $s6  2
			j Debut_recherche_GB
		Cas_GB_0:
			move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_D
			j     DB_GB_Suiv
		Cas_GB_1:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_H						
			j     DB_GB_Suiv
		DB_GB_Suiv:       
			addi  $s6  $s6  1
			addi  $s5  $s5  1
			j Debut_recherche_GB						

	Ligne_B:
		li    $a1  3
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Debut_recherche_B:
			beq   $s5  $a1  PasVoisinNV
			beq   $s6  0	Cas_B_0	#droite
			beq   $s6  1    Cas_B_1	#haut
			beq   $s6  2    Cas_B_2	#gauche
	       		beq   $s6  3    Cas_B_Sub
	        Cas_B_Sub:
			subi  $s6  $s6  3
			j Debut_recherche_B
	        Cas_B_0:
	        	move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_D
			j     DB_B_Suiv
	        Cas_B_1:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_H	        	
			j     DB_B_Suiv
	        Cas_B_2:
	        	move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  Vers_G	
			j     DB_B_Suiv
	        DB_B_Suiv:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Debut_recherche_B		        

	Ligne_G:
		li    $a1  3
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Debut_recherche_G:
			beq   $s5  $a1  PasVoisinNV
			beq   $s6  0	Cas_G_0	#haut
			beq   $s6  1    Cas_G_1	#droite
			beq   $s6  2    Cas_G_2	#bas     
	       	 	beq   $s6  3    Cas_G_Sub
	        Cas_G_Sub:
			subi  $s6  $s6  3
			j Debut_recherche_G
	        Cas_G_0:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_H	
			j     DB_G_Suiv
	        Cas_G_1:
	        	move  $s4  $s1	
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_D
			j     DB_G_Suiv
	        Cas_G_2:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   Vers_B
			j     DB_G_Suiv
	        DB_G_Suiv:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Debut_recherche_G

	Ligne_H:
		li    $a1  3
		jal   Aleatoire
		move  $s6  $a0
		li    $s5  0
		Debut_recherche_H:
			beq   $s5  $a1  PasVoisinNV
			beq   $s6  0	Cas_H_0	#droite
			beq   $s6  1    Cas_H_1	#bas
			beq   $s6  2    Cas_H_2 #gauche 
	        	beq   $s6  3    Cas_H_Sub
	        Cas_H_Sub:
			subi  $s6  $s6  3
			j Debut_recherche_H
	        Cas_H_0:
	        	move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_D
			j     DB_H_Suiv
	        Cas_H_1:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   Vers_B
			j     DB_H_Suiv
	        Cas_H_2:
	        	move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  Vers_G	
			j     DB_H_Suiv
	        DB_H_Suiv:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Debut_recherche_H


	Ligne_D:
		li    $a1  3
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Debut_recherche_D:
			beq   $s5  $a1  PasVoisinNV
			beq   $s6  0	Cas_D_0	#haut
			beq   $s6  1    Cas_D_1	#gauche
			beq   $s6  2    Cas_D_2	#bas     
	       		beq   $s6  3    Cas_D_Sub
	        Cas_D_Sub:
			subi  $s6  $s6  3
			j Debut_recherche_D
	        Cas_D_0:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  Vers_H
			j     DB_D_Suiv
	        Cas_D_1:
	        	move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  Vers_G
			j     DB_D_Suiv
	        Cas_D_2:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   Vers_B
			j     DB_D_Suiv
	        DB_D_Suiv:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Debut_recherche_D												
																			
PasVoisinNV:
	move  $v0  $s1
	li    $v1  -1	
	
FinTVNV:	
	lw    $a0  40($sp)
	lw    $a1  36($sp)
	lw    $a2  32($sp)
	lw    $s0  28($sp) 
	lw    $s1  24($sp)
	lw    $s2  20($sp)
	lw    $s3  16($sp)
	lw    $s4  12($sp)
	lw    $s5  8($sp)
	lw    $s6  4($sp)
	lw    $ra  0($sp)
	addi $sp $sp 44
	jr   $ra
####################Fin TrouveVoisinNV


################## Detruit_mur
# entrees : pile de gen_Final 
#utilisation de l'ad du tableau + offset de case courante et la case precedente + un chifre dans $a1 enntre 0 et 3 pour le mur � d�truire
# 0 => haut
# 1 => droite
# 2 => bas
# 3 => gauche
Detruit_mur:
	#prologue
	subu  $sp  $sp 24  
	sw    $a0  20($sp)
	sw    $a1  16($sp)
	sw    $a2  12($sp)
	sw    $s0  8($sp) 
	sw    $s1  4($sp)
	sw    $ra  0($sp)
	
	
	
	beq   $a1  0  Detruit_MurH
	beq   $a1  1  Detruit_MurD
	beq   $a1  2  Detruit_MurB
	beq   $a1  3  Detruit_MurG
	
Detruit_MurH:
	lw    $t0  24($sp)
	lh    $t1  30($sp)
	lw    $t2  32($sp)
	add   $t3  $t0  $t1
	lw    $t4  0($t3)
	subi  $t4  $t4  4
	sw    $t4  0($t3)
	add   $t3  $t0  $t2
	lw    $t4  0($t3)
	subi  $t4  $t4  1
	sw    $t4  0($t3)
	j     Fin_Detruit_Mur
Detruit_MurD:
	lw    $t0  24($sp)
	lh    $t1  30($sp)
	lw    $t2  32($sp)
	add   $t3  $t0  $t1
	lw    $t4  0($t3)
	subi  $t4  $t4  8
	sw    $t4  0($t3)
	add   $t3  $t0  $t2
	lw    $t4  0($t3)
	subi  $t4  $t4  2
	sw    $t4  0($t3)
	j     Fin_Detruit_Mur
Detruit_MurB:
	lw    $t0  24($sp)
	lh    $t1  30($sp)
	lw    $t2  32($sp)
	add   $t3  $t0  $t1
	lw    $t4  0($t3)
	subi  $t4  $t4  1
	sw    $t4  0($t3)
	add   $t3  $t0  $t2
	lw    $t4  0($t3)
	subi  $t4  $t4  4
	sw    $t4  0($t3)
	j     Fin_Detruit_Mur
Detruit_MurG:
	lw    $t0  24($sp)
	lh    $t1  30($sp)
	lw    $t2  32($sp)
	add   $t3  $t0  $t1
	lw    $t4  0($t3)
	subi  $t4  $t4  2
	sw    $t4  0($t3)
	add   $t3  $t0  $t2
	lw    $t4  0($t3)
	subi  $t4  $t4  8
	sw    $t4  0($t3)
	j     Fin_Detruit_Mur
Fin_Detruit_Mur:
	#epilogue
	lw    $a0  20($sp)
	lw    $a1  16($sp)
	lw    $a2  12($sp)
	lw    $s0  8($sp) 
	lw    $s1  4($sp)
	lw    $ra  0($sp)
	addu  $sp  $sp  24	
	jr    $ra
###############Detruit_mur


#########################debut ecriture-fichier
# entrees : $a0 = taille tableau (n*n), $a1 = adresse du debut du tableau, $a2 = n
# sorties
# ecrit les données du tableau dans le fichier generation.txt
Ecriture_Fichier:
	#prologue
	subu  $sp  $sp  32
	sw    $s0  28($sp) ###Memory[$sp+20] <= $s0
	sw    $s1  24($sp)
	sw    $s2  20($sp)
	sw    $s3  16($sp)
	sw    $a0  12($sp)
	sw    $a1  8($sp)
	sw    $a2  4($sp)
	sw    $ra  0($sp)

	li    $t0  3
	mul   $a2  $a0  $t0
	add   $a2  $a2  $t0
	move  $s0  $a0
	move  $s1  $a1
	move  $s2  $a2
    	beq   $a3  0   EcritReso
	la    $a0  file
	j     file_open
	EcritReso:
		move  $a0  $s7


# ouverture
file_open:
    	li    $v0  13
 	li    $a1  9            
	li    $a2  0x1ff
    	syscall  		# fichier retourner dans $v0
     	move  $a0  $v0  	# appel 15 syscall recquiert $a0
#ecriture
file_write: 
        la    $a1  buffer
	li    $v0  15
	move  $a2  $s2
	syscall
#fermeture
file_close:
	li    $v0  16  		# $a0 est deja le fichier donc pas besoin d'autre commande
	syscall


	#epilogue
	lw    $s0  28($sp)
	lw    $s1  24($sp)
	lw    $s2  20($sp)
	lw    $s3  16($sp)
	lw    $a0  12($sp)
	lw    $a1  8($sp)	
	lw    $a2  4($sp)
	lw    $ra  0($sp)
	addu  $sp  $sp  32
	jr    $ra
#########################fin ecriture fichier

#########################debut case_depart_arrive
# entrees : $a1 : adresse du debut du tableau
# sorties : $v1 offset de depart
# initialisation des valeurs de la case de depart et d'arrive
Case_depart_arrive:
	#epilogue
	subu  $sp  $sp  28
	sw    $s0  24($sp) ###Memory[$sp+20] <= $s0
	sw    $s1  20($sp)
	sw    $s2  16($sp)
	sw    $a0  12($sp)
	sw    $a1  8($sp)
	sw    $a2  4($sp)
	sw    $ra  0($sp)
	
	move  $s1  $a0 		# on sauvegarde la taille complete du tableau
	move  $s0  $a1 		# ainsi que l'adresse de debut de tab

	li    $a0  0
	move  $a1  $a2
	jal   Aleatoire 	# nombre aléatoire entre 0 compris et $a1 non compris  donc si $a1=5 on a [0,1,2,3,4]  possible
	

	subi  $a1  $a1  1
	beq   $a0  $a1  Dep_Ligne_Bas
	beq   $a0  0    Dep_Ligne_Haut

	move  $s2  $a0		# on sauvegarde la ligne choisi dans le cas où ce n'est ni celle du haut ni celle du bas

				# on choisit le coté de la ligne obtenu droite ou gauche
	li    $a0  0
	li    $a1  2
	jal   Aleatoire
			# si on a 0 on commence du coté gauche , si on a 1 on commence du coté droit
	beq   $a0  0  Dep_Ligne_G
	beq   $a0  1  Dep_Ligne_D

Dep_Ligne_G:
	li    $t0  4
	mul   $t1  $a2  $t0 	# on multiplie la talle n avec 4 pour avoir la taille d'une ligne
	mul   $t1  $s2  $t1 	# puis on multiplie le numero de la ligne obtenu au premier aleatoire
	add   $t0  $s0  $t1 	# on rajoute l'ofset créer à l'adresse du debut de tab et on on ajoute 16 au la premier case de la ligne donc on a adresse+a*(n*4) a étant le nombre aléatoire voulu
	lw    $t1  0($t0)
	add   $t1  $t1  16
	sw    $t1  0($t0)
	sub   $v1  $t0  $s0

				# ici on fait fait de meme mais avec le coté droit soit adresse + a*(n*4) + (n-1)*4 
				# pour ariver sur l'addrese de la derniere colonne de la ligne aléatoire
	move  $a1  $a2 
	li    $a0  0
	jal   Aleatoire
	li    $t0  4
	mul   $t2  $a2  $t0
	mul   $t1  $a0  $t2
	subi  $t2  $t2  4
	add   $t1  $t1  $t2
	add   $t0  $s0  $t1
	lw    $t1  0($t0)
	add   $t1  $t1  32
	sw    $t1  0($t0)
	j     Fin_dep


Dep_Ligne_D:

				#comme dep_ligne_g mais d'abord le coté droit puis le coté gauche
	li    $t0  4
	mul   $t2  $a2  $t0
	mul   $t1  $s2  $t2
	subi  $t2  $t2  4
	add   $t1  $t1  $t2
	add   $t0  $s0  $t1
	lw    $t1  0($t0)
	add   $t1  $t1  16
	sw    $t1  0($t0)
	sub   $v1  $t0  $s0
	
	move  $a1  $a2
	li    $a0  0
	jal   Aleatoire
	li    $t0  4
	mul   $t1  $a2  $t0
	mul   $t1  $a0  $t1
	add   $t0  $s0  $t1	
 	lw    $t1  0($t0)
	add   $t1  $t1  32
	sw    $t1  0($t0)
	j     Fin_dep


Dep_Ligne_Haut:
	move  $a1  $a2
	li    $a0  0
	jal   Aleatoire
  	li    $t0  4
	mul   $t1  $a0  $t0 	# a*4
	add   $t0  $s0  $t1 	# addresse de debut + a*4
	lw    $t1  0($t0)
	add   $t1  $t1  16
	sw    $t1  0($t0)	
	sub   $v1  $t0  $s0
	
	li    $a0  0
	jal   Aleatoire	
	li    $t0  4
	mul   $t1  $a0  $t0 	# offset de base sur la ligne
	sub   $t2  $s1  $a2 	# (n*n)-n ($s1 =  n*n sauvegarder au debut de la fonction)
	mul   $t3  $t2  $t0 	# offset du debut de la derniere ligne
	add   $t2  $t3  $t1 	# offset voulu ((n*n)-n) + a*4
	add   $t0  $s0  $t2 	# adresse + ofset 
	lw    $t1  0($t0)
	add   $t1  $t1  32
	sw    $t1  0($t0)
	j     Fin_dep

Dep_Ligne_Bas:
	move  $a1  $a2
	li    $a0  0
 	jal   Aleatoire
	li    $t0  4
	mul   $t1  $a0  $t0 	# offset de base sur la ligne
	sub   $t2  $s1  $a2 	#(n*n)-n ($s1 =  n*n sauvegarder au debut de la fonction)
	mul   $t3  $t2  $t0 	# offset du debut de la derniere ligne
	add   $t2  $t3  $t1 	# offset voulu ((n*n)-n) + a*4
	add   $t0  $s0  $t2 	# adresse + offset 
	lw    $t1  0($t0)
	add   $t1  $t1  16
	sw    $t1  0($t0)
	sub   $v1  $t0  $s0
	
	li    $a0  0
	jal   Aleatoire
	li    $t0  4
	mul   $t1  $a0  $t0 	# a*4
	add   $t0  $s0  $t1 	# addresse de debut + a*4
	lw    $t1  0($t0)
 	add   $t1  $t1 	32
	sw    $t1  0($t0)	
	j     Fin_dep


			# adresse + n*(n-1) + $a0*4
Fin_dep:
	#epilogue
	lw    $s0  24($sp)
	lw    $s1  20($sp)
	lw    $s2  16($sp)
	lw    $a0  12($sp)
	lw    $a1  8($sp)
	lw    $a2  4($sp)
	lw    $ra  0($sp)
	addu  $sp  $sp  28
	jr    $ra
#####################fin case_depart_arrive

#####################début inittab 
# entrees : $a1 = adresse du debut du tableau
# sorties:
# creation des murs avec les valeurs correspondantes 
# et initialisation des valeurs à l'interieur à 0
InitTableau:
	#prologue
	subu  $sp  $sp  28
	sw    $s0  24($sp) ###Memory[$sp+20] <= $s0
	sw    $s1  20($sp)
	sw    $s2  16($sp)
	sw    $a0  12($sp)
	sw    $a1  8($sp)		
	sw    $a2  4($sp)
	sw    $ra  0($sp)

	beq   $a0  $0  taillei0

	move  $s0  $a1
	move  $s2  $a0			# taille max
	li    $t0  4  			# taile d'un mot
	mul   $t0  $s2  $t0 		# taille tableau en entier 
	li    $s2  15			# Valeur de base
	li    $s1  0			# offset

Init0:
	bgt   $s1  $t0  FinInit	
	add   $t1  $s0  $s1
	sw    $s2  0($t1)	
 	addi  $s1  $s1  4
	j     Init0

	move  $s0  $a1		 	# adresse debut


taillei0:
FinInit:
	#epilogue
	lw    $s0  24($sp)
	lw    $s1  20($sp)
	lw    $s2  16($sp)
	lw    $a0  12($sp)
	lw    $a1  8($sp)
	lw    $a2  4($sp)
	lw    $ra  0($sp)
	addu  $sp  $sp  28
	jr    $ra
######################### fin inittab


######################### début creertab
# entrees: $a0: taille (en nombre d'entiers) du tableau à créer
# Pre-conditions: $a0 >=0
# Sorties: $v0: adresse (en octet) du premier entier du tableau
# Post-conditions: si $a0==0, $v0 = 0x00000000
#                 les registres temp. $si sont rétablies si utilisées
CreerTableau:
	#epilogue
	subu  $sp  $sp  24
	sw    $s0  20($sp) ###Memory[$sp+20] <= $s0
	sw    $s1  16($sp)
	sw    $s2  12($sp)
	sw    $a0  8($sp)
	sw    $a1  4($sp)
	sw    $ra  0($sp)

	beq   $a0  $0  taille0
	li    $v0  0		# allocation mémoire
	li    $v0  9 
	mul   $a0  $a0  4
	syscall
	move  $t1  $v0 		# adresse du début du tableau

taille0:
	li    $s0  0

Fin:
	move  $v0  $t1
	# épilogue
	lw    $s0  20($sp)
	lw    $s1  16($sp)
	lw    $s2  12($sp)	
	lw    $a0  8($sp)
	lw    $a1  4($sp)
	lw    $ra  0($sp)
	addu  $sp  $sp  24
	jr    $ra

######################### fin fonction creer_tab 


######Aleatoire
# fonction qui renvois un entier entre 0 et $a1 non compris
Aleatoire:
	li    $v0  42 
	syscall
	jr    $ra
# fin aleatoire

############## Tab_ascii
# entrees: $a0: taille (en nombre d'entiers) du tableau à créer
# Pre-conditions: $a0 = taille du tableau (n*n),$a1 = adresse du debut du tableau et $a2 = n  
# Sorties: 
Tab_ascii:
	#epilogue
	subu  $sp  $sp  32
	sw    $s0  28($sp) 
	sw    $s1  24($sp)
	sw    $s2  20($sp)
	sw    $s3  16($sp)
	sw    $s4  12($sp)
	sw    $s5  8($sp)
	sw    $s6  4($sp)
	sw    $ra  0($sp)
	
	mul   $s0  $a2  $a2	# taille tableau
	move  $s1  $a2 		# n
	la    $s5  buffer
	move  $s6  $s5
	li    $t0  10
	divu  $a2  $t0
	mflo  $t0 		# quotient
	mfhi  $t1 		# reste
	addi  $t0  $t0  48
	addi  $t1  $t1  48
	sb    $t0  0($s5)
	sb    $t1  1($s5)
	li    $t0  10 		# retour a la ligne
	sb    $t0  2($s5)
	addi  $s5  $s5  3
	li    $s2  0
	
Loop_ascii:
	beq   $s2  $s0  Fin_Loop_ascii
	li    $s3  0
	
Loop_Ligne_ascii:
	beq   $s3  $s1  Fin_Loop_Ligne_ascii
	lb    $t1  0($a1)
	li    $t0  10
	divu  $t1  $t0
	mflo  $t0		 # quotient
	mfhi  $t1		 # reste
	addi  $t0  $t0  48
	addi  $t1  $t1  48
	sb    $t0  0($s5)
	sb    $t1  1($s5)
	li    $t1  32
	sb    $t1  2($s5)
	addi  $s3  $s3  1
	addi  $s5  $s5  3
	addi  $a1  $a1  4
	addi  $s2  $s2  1
	j     Loop_Ligne_ascii
	
Fin_Loop_Ligne_ascii:
	li    $t0  10
	sb    $t0  -1($s5)
	j     Loop_ascii
	
Fin_Loop_ascii:
	subu  $a2  $s6  $s5
	move  $a1  $s6 

	#epilogue
	lw    $s0  28($sp)
	lw    $s1  24($sp)
	lw    $s2  20($sp)
	lw    $s3  16($sp)
	lw    $s4  12($sp)
	lw    $s5  8($sp)
	lw    $s6  4($sp)
	lw    $ra  0($sp)
	addu  $sp  $sp  32
	jr    $ra
########################fin fonction Tab_ascii


################################# debut Resolution = fonction principale de la resolution d'un labyrtinthe
Resolution:
#entrees : $a0 = adresse du debut du tableau
#	   $a1 = taille
#	   $a2 = offset
	subu  $sp  $sp  44
	sw    $a0  40($sp)
	sw    $a1  36($sp)
	sw    $a2  32($sp)
	sw    $s0  28($sp) 
	sw    $s1  24($sp)
	sw    $s2  20($sp)
	sw    $s3  16($sp)
	sw    $s4  12($sp)
	sw    $s5  8($sp)
	sw    $s6  4($sp)
	sw    $ra  0($sp)

	move  $s2  $a1
	move  $s3  $sp
	move  $s0  $a0
	move  $s1  $a1
	move  $a1  $a2
	sub   $sp  $sp  4
	sw    $a1  0($sp)
	
		
	add   $t0  $s0  $a1
	lw    $t1  0($t0)   # case de depart : case solution
	addi  $t1  $t1  64
	addi  $t1  $t1  128
	sw    $t1  0($t0)  


	DIRECTION:	
		lw    $s1  0($sp)
		add   $t0  $s0  $s1
		lw    $t1  0($t0)
		subi  $t1  $t1  192
		bgt   $t1  32  Resolu
		bgt   $t1  16  enlev16
		j     casepasdep
	enlev16:  
		subi  $t1  $t1 16
	casepasdep:
		# on regarde tous les cas possibles pour la prochaine case
		beq   $t1  14  Impasse
		beq   $t1  13  Impasse
		beq   $t1  11  Impasse
		beq   $t1  7   Impasse
		beq   $t1  12  DROITE_HAUT
		beq   $t1  10  BAS_HAUT
		beq   $t1  9   BAS_DROITE
		beq   $t1  6   GAUCHE_HAUT
		beq   $t1  5   GAUCHE_DROITE
		beq   $t1  3   GAUCHE_BAS
		beq   $t1  8   BAS_DROITE_HAUT
		beq   $t1  4   GAUCHE_DROITE_HAUT
		beq   $t1  2   GAUCHE_BAS_HAUT
		beq   $t1  1   GAUCHE_BAS_DROITE 
		beq   $t1  0   TOUT_DIR
	

	# quand il n'y a qu'un chemin vers ou allez 
	GO_DROITE:
	GO_BAS:
	GO_GAUCHE:
	GO_HAUT:
		lw    $t0  0($s4)
		addi  $t0  $t0  192
		sw    $t0  0($s4)
		sub   $s4  $s4  $s0
		sub   $sp  $sp  4
		sw    $s4  0($sp)
		j   DIRECTION
	
	
	
	# si on a le choix entre le chemin diu haut ou de droite
	DROITE_HAUT:
		li    $a1  2
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
	Resolution_DH:
		beq   $s5  2    Impasse
		beq   $s6  0    Reso_DH_0	#droite
		beq   $s6  1    Reso_DH_1	#haut
		beq   $s6  2    Reso_Sub_DH
		Reso_Sub_DH:
			subi  $s6  $s6  2
			j Resolution_DH
		Reso_DH_0:
			move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_DROITE
			j     Cas_Suiv_DH
		Reso_DH_1:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_HAUT						
			j     Cas_Suiv_DH
		Cas_Suiv_DH:       
			addi  $s6  $s6  1
			addi  $s5  $s5  1
			j Resolution_DH

	# si on a le choix entre le chemin du bas ou de gauche
	GAUCHE_BAS:
		li    $a1  2
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
	Resolution_GB:
		beq   $s5  2    Impasse
		beq   $s6  0    Reso_GB_0	# gauche
		beq   $s6  1    Reso_GB_1	# bas
		beq   $s6  2    Reso_Sub_GB
		Reso_Sub_GB:
			subi  $s6  $s6  2
			j Resolution_GB	
		Reso_GB_0:
			move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  GO_GAUCHE
			j     Cas_Suiv_GB
		Reso_GB_1:	
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   GO_BAS
			j     Cas_Suiv_GB	
		Cas_Suiv_GB:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_GB
	
	# si on a le choix entre le chemin du bas ou de droite
	BAS_DROITE:
		li    $a1  2
		jal   Aleatoire
		move  $s6  $a0
		li    $s5  0
	Resolution_BD:
		beq   $s5  2    Impasse
		beq   $s6  0    Reso_BD_0	 # droite
		beq   $s6  1    Reso_BD_1 	# en bas
		beq   $s6  2    Reso_Sub_BD
		Reso_Sub_BD: 
			subi  $s6  $s6  2
			j Resolution_BD
		Reso_BD_0:
			move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_DROITE
			j     Cas_Suiv_BD
		Reso_BD_1:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1	 #n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   GO_BAS
			j      Cas_Suiv_BD
		 Cas_Suiv_BD:       
			addi  $s6  $s6  1
			addi  $s5  $s5  1
			j Resolution_BD
	
	# si on a le choix entre le chemin du bas ou de haut
	BAS_HAUT:
		li    $a1  2
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
	Resolution_BH:
		beq   $s5  2    Impasse
		beq   $s6  0    Reso_BH_0	#bas
		beq   $s6  1    Reso_BH_1	#haut
		beq   $s6  2    Reso_Sub_BH
		Reso_Sub_BH:
			subi  $s6  $s6  2
			j Resolution_BH
		Reso_BH_0:				
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  GO_BAS			
			j     Cas_Suiv_BH
		Reso_BH_1:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_HAUT	
			j     Cas_Suiv_BH						
		Cas_Suiv_BH:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_BH	
	
	
	# si on a le choix entre le chemin du haut ou de gauche
	GAUCHE_HAUT:
		li    $a1  2
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
	Resolution_GH:
		beq   $s5  2    Impasse
		beq   $s6  0    Reso_GH_0	#gauche
		beq   $s6  1    Reso_GH_1	#haut
		beq   $s6  2    Reso_Sub_GH
		Reso_Sub_GH:
			subi  $s6  $s6  2
			j Resolution_GH
		Reso_GH_0:				
			move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  GO_GAUCHE				
			j     Cas_Suiv_GH
		Reso_GH_1:
			move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_HAUT	
			j     Cas_Suiv_GH						
		Cas_Suiv_GH:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_GH	
	
	# si on a le choix entre le chemin du droite ou de gauche
	GAUCHE_DROITE:
		li    $a1  2
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
	Resolution_GD:
		beq   $s5  2    Impasse
		beq   $s6  0    Reso_GD_0	#gauche
		beq   $s6  1    Reso_GD_1	#droite
		beq   $s6  2    Reso_Sub_GD
		Reso_Sub_GD:
			subi  $s6  $s6  2
			j Resolution_GD
		Reso_GD_0:				
			move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  GO_GAUCHE				
			j     Cas_Suiv_GD
		Reso_GD_1:
			move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_DROITE
			j     Cas_Suiv_GD						
		Cas_Suiv_GD:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_GD
	

	# si on a le choix entre le chemin du bas ou de droite ou du haut
	BAS_DROITE_HAUT:
		li    $a1  3
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Resolution_BDH:
			beq   $s5  $a1  Impasse
			beq   $s6  0	Reso_BDH_0	#haut
			beq   $s6  1    Reso_BDH_1	#droite
			beq   $s6  2    Reso_BDH_2	#bas     
	        	beq   $s6  3    Reso_Sub_BDH
	        Reso_Sub_BDH:
			subi  $s6  $s6  3
			j Resolution_BDH
	        Reso_BDH_0:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_HAUT	
			j     Cas_Suiv_BDH
	        Reso_BDH_1:
	        	move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_DROITE
			j     Cas_Suiv_BDH
	        Reso_BDH_2:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   GO_BAS
			j     Cas_Suiv_BDH
	        Cas_Suiv_BDH:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_BDH
		        
	# si on a le choix entre le chemin de gauche ou de droite ou du haut	        
	GAUCHE_DROITE_HAUT:
		li    $a1  3
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Resolution_GDH:
			beq   $s5  $a1  Impasse
			beq   $s6  0	Reso_GDH_0	#haut
			beq   $s6  1    Reso_GDH_1	#droite
			beq   $s6  2    Reso_GDH_2	#gauche    
	       		beq   $s6  3    Reso_Sub_GDH
	        Reso_Sub_GDH:
			subi  $s6  $s6  3
			j Resolution_GDH
	        Reso_GDH_0:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_HAUT	
			j     Cas_Suiv_GDH
	        Reso_GDH_1:
	        	move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_DROITE
			j     Cas_Suiv_GDH
	        Reso_GDH_2:
	        	move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  GO_GAUCHE
			j     Cas_Suiv_GDH
	        Cas_Suiv_GDH:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_GDH
		        
	# si on a le choix entre le chemin du bas ou de gauche ou du haut
	GAUCHE_BAS_HAUT:
	li    $a1  3
	jal Aleatoire
	move  $s6  $a0
	li    $s5  0
		Resolution_GBH:
			beq   $s5  $a1  Impasse
			beq   $s6  0	Reso_GBH_0	#haut
			beq   $s6  1    Reso_GBH_1	#gauche
			beq   $s6  2    Reso_GBH_2	#bas     
	        	beq   $s6  3    Reso_Sub_GBH
	        Reso_Sub_GBH:
			subi  $s6  $s6  3
			j Resolution_GBH
	        Reso_GBH_0:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_HAUT
			j     Cas_Suiv_GBH
	        Reso_GBH_1:
	        	move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  	#offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  GO_GAUCHE
			j     Cas_Suiv_GBH
	        Reso_GBH_2:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   GO_BAS
			j     Cas_Suiv_GBH
	       Cas_Suiv_GBH:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_GBH
		        
	# si on a le choix entre le chemin du bas ou de droite ou de droite
	GAUCHE_BAS_DROITE: 	
		li    $a1  3
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Resolution_GBD:
			beq   $s5  $a1  Impasse
			beq   $s6  0	Reso_GBD_0	#bAS
			beq   $s6  1    Reso_GBD_1	#droite
			beq   $s6  2    Reso_GBD_2	#Gauche    
	        	beq   $s6  3    Reso_Sub_GBD
	        Reso_Sub_GBD:
			subi  $s6  $s6  3
			j Resolution_GBD
	        Reso_GBD_0:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 #n*4	
			add   $s4  $s4  $t0 #offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   GO_BAS
			j     Cas_Suiv_GBD
	        Reso_GBD_1:
	        	move  $s4  $s1
			addi  $s4  $s4  4 #offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_DROITE
			j     Cas_Suiv_GBD
	        Reso_GBD_2:
	        	move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1  #offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  GO_GAUCHE
			j     Cas_Suiv_GBD
	        Cas_Suiv_GBD:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_GBD
	
	#si on a le choix entre chaque chemin
	TOUT_DIR:
		li    $a1  4
		jal Aleatoire
		move  $s6  $a0
		li    $s5  0
		Resolution_TD:
			beq   $s5  $a1  Impasse
			beq   $s6  0	Reso_TD_0	#BAS
			beq   $s6  1    Reso_TD_1	#droite
			beq   $s6  2    Reso_TD_2	#Gauche
			beq   $s6  3    Reso_TD_3	#Haut
	       		beq   $s6  4    Reso_Sub_TD
	        Reso_Sub_TD:
			subi  $s6  $s6  4
			j Resolution_TD
	        Reso_TD_0:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2 
			mul   $t0  $t0  $t1 	#n*4	
			add   $s4  $s4  $t0 	#offset base + n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128   GO_BAS
			j     Cas_Suiv_TD
	        Reso_TD_1:
	        	move  $s4  $s1
			addi  $s4  $s4  4 	#offset de base + 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_DROITE
			j     Cas_Suiv_TD
	        Reso_TD_2:
	        	move  $s4  $s1
			li    $t1  4	
			sub   $s4  $s4  $t1 	 #offset de base - 4
			add   $s4  $s0  $s4
			lw    $t3  0($s4) 
			blt   $t3  128  GO_GAUCHE
			j     Cas_Suiv_TD
		Reso_TD_3:
	        	move  $s4  $s1
			li    $t1  4
			move  $t0  $s2  
			mul   $t0  $t0  $t1 	#n*4	
			sub   $s4  $s4  $t0 	#offset base - n*4
			add   $s4  $s0  $s4
			lw    $t3  0($s4)
			blt   $t3  128  GO_HAUT	
			j     Cas_Suiv_TD
	        Cas_Suiv_TD:       
		 	addi  $s6  $s6  1
		        addi  $s5  $s5  1
		        j Resolution_TD
	
	# cas ou on n'a plus de solution, on depile la pile afin de revenir en arriere
	Impasse:
		lw    $t2  0($sp)
		beq   $t2  $a1  CasDebutReso
		addi  $sp  $sp  4
		add   $t0  $s0  $s1
		lw    $t1  0($t0)
		subi  $t1  $t1  64
		sw    $t1  0($t0)
		j     DIRECTION
	
	# cas special de la premiere case
	CasDebutReso:
		beq   $t1  14  Reso_TD_3
		beq   $t1  13  Reso_TD_1
		beq   $t1  11  Reso_TD_0
		beq   $t1  7   Reso_TD_2
	
	# on enleve 192 au chemin solution
	Resolu:
	add   $t0  $s0  $s1
	lw    $t1  0($t0)
	subi  $t1  $t1  192
	sw    $t1  0($t0)
	
	
	subu  $t1  $s3  $sp
	add   $sp  $sp  $t1
	
	
	lw    $a0  40($sp)
	lw    $a1  36($sp)
	lw    $a2  32($sp)
	lw    $s0  28($sp) 
	lw    $s1  24($sp)
	lw    $s2  20($sp)
	lw    $s3  16($sp)
	lw    $s4  12($sp)
	lw    $s5  8($sp)
	lw    $s6  4($sp)
	lw    $ra  0($sp)
	addi $sp $sp 44
	jr   $ra
#####################fin resolution


########################debut tab_valeur
# entrees: $a0: taille (en nombre d'entiers) du tableau à créer
# Pre-conditions: $a0 = taille du tableau (n*n),$a1 = adresse du debut du tableau et $a2 = n  
# Sorties: 
Tab_valeur:
	#epilogue
	subu  $sp  $sp  32
	sw    $s0  28($sp) 
	sw    $s1  24($sp)
	sw    $s2  20($sp)
	sw    $s3  16($sp)
	sw    $s4  12($sp)
	sw    $s5  8($sp)
	sw    $s6  4($sp)
	sw    $ra  0($sp)
	
	move $s0  $a0
    	li   $a1  0          		  # Ouverture en lecture
   	jal  OuvrirFichier
    	move $s1  $v0         		 # s1 : Descripteur du fichier
    	
    	# Lecture de l'entête du fichier
	move $a0  $s1        		# Descripteur du fichier
	la   $a1  buffer       		# Adresse du buffer
	li   $a2  3        
	jal  LireFichier
Taille_resolu:
	li   $t3  10
	lb   $t0  0($a1)		# $t0 contient le chiffre de la dizaine
	lb   $t1  1($a1)		# $t1 contient le chiffre de l'unite
	subi $t0  $t0  48		# pour ne plus etre ne ascii
	subi $t1  $t1  48
	mul  $t0  $t0 $t3			# valeur en dizaine corretce
	add  $t0  $t0 $t1 		# valeur dans $t0
	move $s0  $t0 			# sauvegarde de n dans $s0
	move $s3  $t0
	mul  $a0  $s0  $s0			# $a0 taille tableau n*n
	move $s0  $a0
	jal  CreerTableau
	move $s6  $v0			# $s6 adresse du début du tableau
	move $s5  $v0
	li   $t0  3
    	mul  $a2  $s3  $s3
    	mul  $a2  $a2  $t0 
    	addi $a2  $a2  3		# Nombre d'octets à lire
    	    
    	# Lecture de l'entête du fichier
	move $a0  $s1        		# Descripteur du fichier
	la   $a1  buffer       		# Adresse du buffer     
	jal  LireFichier
	li   $s2  0

Loop_valeur:
	beq   $s2  $s0  Fin_Loop_valeur
Loop_Ligne_valeur:
	li   $t3  10
	lb   $t0  0($a1)		# $t0 contient le chiffre de la dizaine
	lb   $t1  1($a1)		# $t1 contient le chiffre de l'unite
	subi $t0  $t0  48		# pour ne plus etre ne ascii
	subi $t1  $t1  48
	mul  $t0  $t0  $t3		# valeur en dizaine corretce
	add  $t0  $t0  $t1 		# valeur dans $t0
	sw   $t0  0($s5)		
	add  $a1  $a1  3
	add  $s5  $s5  4
	j    Fin_Loop_Ligne_valeur
Fin_Loop_Ligne_valeur:
	add   $s2  $s2  1
	j     Loop_valeur
	
Fin_Loop_valeur:
	move  $a0  $s1 		# onferme d'abord le fichier
	move  $a1  $s3 		# taille
	li    $v0  16  		# $a0 already has the file descriptor
	syscall
	move  $a0  $s6  	# on rajoute l'adresse ensuite
	#epilogue
	lw    $s0  28($sp)
	lw    $s1  24($sp)
	lw    $s2  20($sp)
	lw    $s3  16($sp)
	lw    $s4  12($sp)
	lw    $s5  8($sp)
	lw    $s6  4($sp)
	lw    $ra  0($sp)
	addu  $sp  $sp  32
	jr    $ra
######################## Fin  Tab_valeur

########################debut ouvrirfichier
# Paramètres :
# a0 :  fichier à ouvrir.
# a1 : Flag (0 : lecture, 1 : écriture)
# sorties : v0 : Descripteur de fichier.
OuvrirFichier:
#prologue
subiu  $sp  $sp  12
sw     $ra  0($sp)
sw     $a0  4($sp)
sw     $a1  8($sp)

li     $a2  0        # 0 : Ignorer le mode
li     $v0  13
syscall

# Erreur d'ouverture du fichier si v0 < 0.
bltz   $v0  OuvrirFichierErreur
j      OuvrirFichierEpilogue
OuvrirFichierErreur:
        jal   Erreur

OuvrirFichierEpilogue:
#epilogue
lw     $ra  0($sp)
lw     $a0  4($sp)
lw     $a1  8($sp)
addiu  $sp  $sp  12
jr     $ra
########################fin ouvrirfichier

########################debut LireFichier 
# Paramètres :
# a0 : Descripteur de fichier.
# a1 : Buffer.
# a2 : Nombre d'octets à lire.
#sorties  v0 : Nombre d'octets lus.

LireFichier:
#prologue
subiu  $sp  $sp  16
sw     $ra  0($sp)
sw     $a0  4($sp)
sw     $a1  8($sp)
sw     $a2  12($sp)

li     $v0  14
syscall

# erreur de lecture du fichier si v0 < 0.
bltz   $v0  LireFichierErreur
j      LireFichierEpilogue
LireFichierErreur:
        la     $a0  ERRREAD
        jal    Erreur

LireFichierEpilogue:
#epilogue
lw     $ra  0($sp)
lw     $a0  4($sp)
lw     $a1  8($sp)
lw     $a2  12($sp)
addiu  $sp  $sp  16
jr     $ra
########################fin lirefichier


# Paramètres :
# a0 : Chaîne de caractères.
#sortie : v0 : Chaîne de caractères.
# Supprime les '\n' en trop dans une chaîne de caractères.

ChercheBSlashN:
#prologue
subiu  $sp  $sp  8
sw     $a0  4($sp)
sw     $ra  0($sp)

move   $t0  $a0
li     $t1  10       # t1 : Valeur ASCII de '\n'
li     $t2  0        # t2 : Valeur ASCII de '\0'
LoopCherche:
	lb    $t3  0($t0)
        beqz  $t3  FinLoopCherche # Teste si $t3 = '\0'
        beq   $t3  $t1  SupprimerChariot
        addi  $t0  $t0  1      # Incrément $t0
        j     LoopCherche
SupprimerChariot:
        sb    $0  0($t0)
        j     FinLoopCherche
FinLoopCherche:
   	move  $v0  $a0

#epilogue
lw     $a0  4($sp)
lw     $ra  0($sp)
addiu  $sp  $sp  8
jr     $ra
########################fin chercheBSlashN

########################debut afficherstring
# Paramètres :
# a0 : Chaîne à afficher.

AfficherString:
#prologue
subiu  $sp  $sp  8
sw     $ra  0($sp)
sw     $a0  4($sp)

li     $v0  4
syscall

#epilogue
lw     $ra  0($sp)
lw     $a0  4($sp)
addiu  $sp  $sp  8
jr     $ra

########################fin afficherstring

########################debut entree
# Paramètres :
# a0 : Taille buffer.
# v0 : Buffer de la chaîne de caratères.
Entree:
#prologue
subiu  $sp  $sp  8
sw     $a0  4($sp)
sw     $ra  0($sp)

# Lecture d'une string de taille a0 au maximum.
move   $a1  $a0    # a1 : Taille du buffer.
la     $a0  BUFFER    # a0 : Adresse du buffer. 
li     $v0  8        # read string
syscall
move   $v0  $a0

# epilogue
lw     $a0  4($sp)
lw     $ra  0($sp)
addiu  $sp  $sp  8
jr     $ra
########################fin entree

########################debut erreur 
# Paramètres :
# a0 : Chaîne à afficher.

Erreur:
#prologue
subiu  $sp  $sp  8
sw     $ra  0($sp)
sw     $a0  4($sp)

jal    AfficherString
jal    Exit

#epilogue
lw     $ra  0($sp)
lw     $a0  4($sp)
addiu  $sp  $sp  8
jr     $ra
########################fin erreur


######################## debut RajouteResolu
## entrees : $a0 la chaine de caractères
## sorties : $v0 chaine de caractère avec .resolu 
RajouteResolu:

#prologue
subiu  $sp  $sp  20
sw     $s0  16($sp)
sw     $s1  12($sp)
sw     $a1  8($sp)
sw     $a0  4($sp)
sw     $ra  0($sp)

move  $s0  $a0 
li    $t1  46     # valeur ascii '.'
li    $t2  114    # valeur ascii 'r'
li    $t3  101    # valeur ascii 'e'
li    $t4  115    # valeur ascii 's'
li    $t5  111    # valeur ascii 'o'
li    $t6  108    # valeur ascii 'l'
li    $t7  117    # valeur ascii 'u'

LoopEcriture:
	lb     $t0  0($s0)
	li     $s1  0
	beq    $t0  $t1  ajoutResolu
	addiu  $s0  $s0  1
	addi   $s1  $s1  1
	j      LoopEcriture
	# on rajoute ".resolu" a la fin du fichier 
	ajoutResolu:
	        addi   $s0  $s0  4
		sb     $t1  0($s0)
		addiu  $s0  $s0  1
		sb     $t2  0($s0)
		addiu  $s0  $s0  1
		sb     $t3  0($s0)
		addiu  $s0  $s0  1
		sb     $t4  0($s0)
		addiu  $s0  $s0  1
		sb     $t5  0($s0)
		addiu  $s0  $s0  1
		sb     $t6  0($s0)
		addiu  $s0  $s0  1
		sb     $t7  0($s0)
		addiu  $s0  $s0  1
		li     $t0  0
		addi   $s1  $s1  11
		Vidage:
			beq   $s1  128  FinLoopEcriture
			sb    $t0  0($s0)
			addi  $s1  $s1  1
			addi  $s0  $s0  1
			j     Vidage

FinLoopEcriture:
	move  $v0  $a0

#epilogue
lw     $s0  16($sp)
lw     $s1  12($sp)
lw     $a1  8($sp)
lw     $a0  4($sp)
lw     $ra  0($sp)
addiu  $sp  $sp  20
jr     $ra
######################## Fin RajouteResolu

########################debut TrouveCaseDepart
## Entree:  $a1: n    et $a0 adresse debut tableau
TrouveCaseDepart:
#prologue
subiu  $sp  $sp  24
sw     $s0  20($sp)
sw     $s1  16($sp)
sw     $s2  12($sp)
sw     $a1  8($sp)
sw     $a0  4($sp)
sw     $ra  0($sp)


move  $s1  $a1
move  $s0  $a0
mul   $s2  $s1  $s1
li    $s1  0

TrouveCase:
	bgt   $s1   $s2  CaseTrouver
	lw    $t0   0($s0)
	bgt   $t0   16   DeuxCond
	j     SuiteTrouveCase
	DeuxCond: 
	blt  $t0  32 CaseTrouver
SuiteTrouveCase:
	addi  $s1   $s1  1	
	addi  $s0   $s0  4
	j     TrouveCase

CaseTrouver:
	li    $t0   4
	mul   $v0   $s1  $t0

lw     $s0  20($sp)
lw     $s1  16($sp)
lw     $s2  12($sp)
lw     $a1  8($sp)
lw     $a0  4($sp)
lw     $ra  0($sp)
addiu  $sp  $sp  20
jr     $ra
############## fin trouvecasedepart

######### }}} FIN DES FONCTIONS
