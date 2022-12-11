## Grammar

```
statement_list   := statement
                 |  statement statement_list
                 | <empty>

statement        := expr ;

expr             := ( expr )
                 |  ( expr ) OP expr
                 |  INTEGER
                 |  INTEGER OP expr
```
