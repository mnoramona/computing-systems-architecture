###### Mitran Ramona Luminita, grupa 333CC

# Tema 2 ASC - Implementarea CUDA a algoritmului de consens Proof of Work din cadrul Bitcoin

## Implementare
- Implementarea functiei _findNonce_ 
    - Are trei parametri: *block_content*, care reprezinta continutul blocului pentru care se cauta nonce-ul, *block_hash*, care reprezinta hash-ul acestui bloc, si *yes_nonce*,
    un pointer catre variabila in care se va stoca nonce-ul gasit.
    - Am folosit definirea sirului de caractere *difficulty_5_zeros* din utils.cu pentru a verifica daca nonce-ul gasit respectă dificultatea ceruta.
    - Am declarat doua variabile locale pentru a efectua copii locale ale continutului blocului și ale hash-ului. Aceste copii sunt folosite pentru a evita modificarea datelor originale
    (ca M-AU DISTRUS... Asta e si motivul intarzierii).
    - Am declarat un sir de caractere *nonce_string* pentru a reprezenta nonce-ul sub forma de sir de caractere.
    - Am calculat indexul fiecarui thread din bloc si un pas de incrementare pentru a parcurge nonce-ul. (M-am inspirat din laborator).
    - Am paralelizat for-ul pe care l-am vazut in cpu_miner.cu, pentru a gasi nonce-ul, care itereaza pornind de la indexul thread-ului curent și incrementand cu pasul *stride*.
    - Nonce-ul este adăugat la conținutul blocului, astfel încât fiecare thread să își modifice PROPRIA COPIE a conținutului blocului.
    - Nonce-ul numeric este convertit intr-un sir de caractere folosind functia *intToString*.
    - Șirul *nonce* este adaugat la copia locala a continutului blocului.
    - Se aplica functia SHA256 asupra copiei locale a continutului blocului pentru a calcula hash-ul.
    - Se verifica daca hash-ul calculat indeplineste conditia de dificultate specificata (sa inceapacu cinci zerouri). Daca da, nonce-ul este stocat in variabila *yes_nonce*, iar hash-ul
    este copiat in block_hash. Apoi, break.

- In main
    - Am adaugat la codul original declarari si alocari de memorie pe dispozitiv pentru variabilele *d_block_content*, *d_block_hash* și *d_nonce*.
    - Am copiat continutul blocului si hash-ul blocului pe dispozitiv si declar un pointer *block_hash* pentru a stoca hash-ul blocului pe gazda.
    - Se calculeaza dimensiunea blocului si numarul total de blocuri necesare pentru *findNonce*. Pe care o si apelez.
    - Copiez nonce-ul si hash-ul blocului inapoi de pe dispozitivul GPU pe gazda si le dau print.

## Rezultate
- Nu stiu ar trebui sa zic aici mai exact. Am rulat codul si a mers. Am obtinut un nonce si un hash care incepe cu 5 zerouri.

[ramona.mitran@fep8 gpu_miner]$ cat results.csv 
0000053386721ff64e5938301c0a738171ab477f8370b267688a23febf11e000,99337409,0.43

- good.