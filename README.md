# distGraph
Bibliothèque d'algorithme distribués de graphes  pour architectures hétérogènes


# Prérequis

- dub https://code.dlang.org/ 
- dmd 2.7 https://dlang.org/ ou gdc-5
- MPI


# Installation

`./configure`
Cette commande permet de copier le wrap MPI pour D dans un endroit accessible (~/libs/)

`make install` ou `make install5`
Compile la bibliothèque, et renseigne dub de son emplacement
(install5 utilise gdc-5 au lieu de dmd 2.7)


# Test

les tests sont dans le dossier sample.

	- graphTest :
		Test de création d'un graphe à partir d'un fichier (génére les partitions et le transforme en .dot)
		
	- mpiTest :
	  Test du wrap de MPI.
	  
	- spawn:
		exemple de création de thread communicant en D.
		
	


