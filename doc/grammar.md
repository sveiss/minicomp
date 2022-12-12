## Grammar

```
statement_list   := statement
                 |  statement statement_list
                 | <empty>

statement        := expr ;
                 |  var_definition ;
                 |  var_assignment ;

var_definition   := TYPE IDENTIFIER
var_assignment   := IDENTIFIER = expr

expr             := ( expr )
                 |  ( expr ) OP expr
                 |  INTEGER
                 |  INTEGER OP expr
                 |  IDENTIFIER
                 |  IDENTIFIER OP expr
```
