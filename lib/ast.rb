# frozen_string_literal: true

require "./lib/visitors"

module AST
  class Node
    include AcceptsVisitorMixin
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
end
