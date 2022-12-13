# frozen_string_literal: true

require "./lib/visitors"

module AST
  class Node
    include AcceptsVisitorMixin
  end

  class StatementList < Node
    attr_reader :statements

    def initialize(statements:)
      super()
      @statements = statements
    end

    def to_s = statements.map { "#{_1}\n" }
  end

  class ExprStatement < Node
    attr_reader :expr

    def initialize(expr:)
      super()
      @expr = expr
    end

    def to_s = "#{expr} ;\n"
  end

  class Expr < Node
    attr_reader :left, :right, :op

    def initialize(left:, right:, op:)
      super()
      @left = left
      @right = right
      @op = op
    end

    def to_s = " ( #{left} #{op} #{right} ) "
  end

  class IVal < Node
    attr_reader :val

    def initialize(val:)
      super()
      @val = val.to_i
    end

    def to_s = @val.to_s
  end

  class VarDefinition < Node
    attr_reader :variable

    def initialize(variable:)
      super()
      @variable = variable
    end

    def to_s = "int #{variable} ;"
  end

  class VarAssignment < Node
    attr_reader :variable, :value

    def initialize(variable:, value:)
      super()
      @variable = variable
      @value = value
    end

    def to_s = "#{variable} = #{value} ;"
  end

  class VarReference < Node
    attr_reader :variable

    def initialize(variable:)
      super()
      @variable = variable
    end

    def to_s = variable.to_s
  end

  class FnDefinition < Node
    attr_reader :name, :body

    def initialize(name:, body:)
      super()
      @name = name
      @body = body
    end

    def to_s = "fn #{name} { #{body} }"
  end

  class FnCall < Node
    attr_reader :name, :body

    def initialize(name:)
      super()
      @name = name
    end

    def to_s = "#{name}()"
  end
end
