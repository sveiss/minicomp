## Grammar

```
toplevel_list    := toplevel
                 |  toplevel function_list
                 |  <empty>

toplevel         := function
                 |  statement

fn_definition    | fn IDENTIFIER { statement_list }

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
                 |  term
                 |  term OP expr

term             := INTEGER
                 |  var_reference
                 |  function_call

var_reference    := IDENTIFIER

fn_call          := IDENTIFIER()
```
