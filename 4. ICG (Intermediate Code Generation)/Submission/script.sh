yacc -Wall -d -g -y -v 1705107.y
echo '1'
g++ -std=c++17 -Wall -g -c -o y.o y.tab.c
echo '2'
flex 1705107.l		
echo '3'
g++ -std=c++17 -Wall -g -c -o l.o lex.yy.c
#g++ -std=c++17 -Wall -c SymbolTable.h -o SymbolTable.o
echo '4'
g++ -std=c++17 -Wall -g y.o l.o -o a.out
echo '5'
./a.out input.c