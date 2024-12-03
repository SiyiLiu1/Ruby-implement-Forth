# for Forth.rb:
in Windows10's cmd:
type: 
ruby forth.rb
then it appear:
>
exit by type "exit" or "quit", case insensitive

The Forth interpreter starts with an empty stack and the following dictionary of words:
• +, -, *, / and mod (all ( n1 n2 -- n3 ) where n3 is the result of the operation) add, subtract, multiply, divide and calculate the division remainder for the top two stack values and then push the result back to the stack.
• DUP ( n -- n n ) duplicates the TOS,
• SWAP ( n1 n2 -- n2 n1 ) swaps the first two elements on the TOS,
• DROP ( n -- ) pops the TOS and discards it,
• DUMP ( -- ) prints the stack without modifying it,
• OVER ( n1 n2 -- n1 n2 n1 ) takes the second element from the stack and copies it to the TOS,
• ROT ( n1 n2 n3 -- n2 n3 n1 ) rotates the top three elements of the stack,
• . ( n -- ) pops the TOS and prints the value as an integer,
• EMIT ( n -- ) pops the TOS and prints the value as an ASCII character,
• CR ( -- ) prints a newline,
• =, < and > (all ( n1 n2 -- n3 )) all pop two elements from the TOS and push -1 to the TOS if the first element is equal, smaller than, or greater than the second element, respectively; otherwise, 0 is pushed to the TOS,
• AND, OR and XOR (all ( n1 n2 -- n3 )) pop two elements from the TOS and push back bitwise and, or and xor respectively of the first and second elements to the TOS,
• INVERT ( n1 -- n2 ) pops a value from the TOS and pushes its bitwise negation (inversion) back, and
• ." indicates the beginning of a string that is terminated by a subsequent word that ends with ".

The interpreter then keeps reading lines from standard input. Each line is a set of words separated by one or more whitespace
characters. If the line was evaluated successfully, the interpreter prints ok. Otherwise, an appropriate error message is
displayed.

define new words. How? Simple: a word is just a collection of other words and values. In Forth, a definition starts with the word : that is followed by the name of the new word. Afterwards, the definition
follows until a ; word is encountered. 
Forth comes with the control structure statement IF <true> (ELSE <false>) THEN that executes the <true> block if the TOS is non-zero; 
otherwise, <false> block is executed if it exists. 
In either case, the execution continues after THEN.

Forth also defines two loop structures: BEGIN <body> UNTIL and DO <body> LOOP. 
BEGIN loops are similar to while loops in other languages: the loop body <body> is executed until the 
UNTIL encounters a non-zero value at the TOS (which it pops, of course). 
BEGIN does nothing to the stack.
DO ... LOOP is a bit different. DO pops two values from the stack: begin and end. 
It sets a loop counter to begin and repeats the loop body while incrementing the counter until it reaches end (c.f. Python's for i in range(begin, end)). The counter
can be accessed within the loop by the word I that pushes the current counter to the TOS.
Note: both : and ; are words and are thus separated by space! 
Note: ; does not necessarily have to end on the line where : began. Same goes for THEN/UNTIL/LOOP, and the corresponding IF/BEGIN/DO. 
Note: I ( -- n ) returns an error outside the DO...LOOP construct.

Forth also allows you to name constants and save values in the heap memory through variables. With variables, you can keep track of changing values without having to store them on the stack.
Here's an overview of the variable-related words:
• VARIABLE name defines the variable name. name then becomes a word that pushes its heap memory address to the TOS.
In your implementation, the addresses should start at 1000.
• name ! pops the TOS and stores the popped value in the name’s location at the heap (in C, this would be *name = stack.pop()).
• name @ pushes the value stored in the name’s location to the TOS (in C, this would be stack.push(*name)).
Hint: The following helper might be useful: : ? @ . ;.
• value CONSTANT name defines the constant name that points to value. This operation uses neither heap nor stack.
• ALLOT pops a value n from the TOS and reserves a contiguous block of size n in the current location of the heap. It is
always used in conjunction with CELLS which multiplies the TOS with the cell width (in your implementation, the cell
width will always be 1). For example, VARIABLE n 3 CELLS ALLOT might assign address 1000 to the variable n and then
reserve addresses 1001, 1002 and 1003. If you do VARIABLE p afterwards, p will then point to 1004, not to 1001 (which
is a correct answer if there was no ALLOT). ALLOT is useful for creating contiguous arrays.


Examples: 
> 2 4 6 8 . . . . ( comments are enclosed within parens. Example input is indented. )
8 6 4 2 ok
> 5 6 + 7 8 + * . ( simple calculation )
165 ok
> 5 DUMP 6 DUMP + DUMP 7 DUMP 8 DUMP + DUMP * DUMP . DUMP
[5]
[5, 6]
[11]
[11, 7]
[11, 7, 8]
[11, 15]
[165]
165
[]
ok
> 42 0 SWAP - .     
-42 ok
> 100 0 mOD .
error: divided by 0
> 48 DUP ." The top 
of the stack is " . CR ." which 
looks like '" DUP EMIT ." ' in 
ASCII"
The top of the stack is 48   
which looks like '0' in ASCII
ok
> 5 6 + 7 8 + * .
165 ok
> : neg 0 SWAP - ; ( negate the number )
ok
> 5 neg .
-5 ok
> : fac ( n1 -- n2 ) DUP 1 >                                
IF DUP 1 - fac *
ELSE DROP 1 THEN
;
ok
> 5 fac .
120 ok
> 23 DUP 18 < IF ." reject " ELSE
DUP 21 < IF ." small " ELSE
DUP 24 < IF ." medium " ELSE
DUP 27 < IF ." large " ELSE
DUP 30 < IF ." extra large " ELSE
." error "
THEN THEN THEN THEN THEN DROP
medium 
ok
> VARIABLE numbers 3 CELLS ALLOT ( array of size 4 )
ok
> 10 numbers 0 CELLS + !
ok
> 20 numbers 1 CELLS + !
ok
> 30 numbers 2 CELLS + !
ok
> 40 numbers 3 CELLS + !
ok
> 2 CELLS numbers + ?
30 ok
> 3 CONSTANT third
ok
> third CELLS numbers + ?
40 ok

