# frozen_string_literal: true

module AST
  class Node
    def accept(visitor)
      raise NotImplementedError, "should be overridden"
    end
  end

  class Expr < Node
    attr_reader :left, :right, :op

    def initialize(left:, right:, op:)
      super()
      @left = left
      @right = right
      @op = op
    end

    def accept(visitor)
      visitor.visit_expr(self)
    end

    def to_s = " ( #{left} #{op} #{right} ) "
  end

  class IVal < Node
    attr_reader :val

    def initialize(val:)
      super()
      @val = val.to_i
    end

    def accept(visitor)
      visitor.visit_ival(self)
    end

    def to_s = @val.to_s
  end
end
