# frozen_string_literal: true

require "./lib/ast"
require "strscan"

class Parser
  class ScannerError < StandardError
    attr_accessor :pos
  end

  def initialize(input)
    @s = StringScanner.new(input)
  end

  INTEGER = /\d+/
  OPEN_PAREN = /\(/
  CLOSE_PAREN = /\)/
  OP = %r{[+*/-]}
  IDENTIFIER = /[a-zA-Z_]+[a-zA-Z_0-9]*/
  TYPE = /int/

  def parse
    statement_list
  rescue ScannerError => e
    ne = ScannerError.new("#{e.message} in #{@current_rule} at #{@s.pos}")
    ne.pos = @s.pos
    raise ne
  end

  private

  # production rules

  def statement_list
    @current_rule = "statement_list"
    statements = []

    statements << statement until eos?
    AST::StatementList.new(statements: statements)
  end

  def statement
    @current_rule = "statement"
    ret = if match?(TYPE)
      var_definition
    elsif match?(IDENTIFIER)
      # maybe assign or expr (in the real world, solved by assignment being a type of expr...)
      saved_pos = @s.pos
      scan(IDENTIFIER)
      is_assignment = match?("=")
      @s.pos = saved_pos

      if is_assignment
        var_assignment
      else
        AST::ExprStatement.new(expr: expr)
      end
    else
      AST::ExprStatement.new(expr: expr)
    end

    expect(";")

    ret
  end

  def var_definition
    @current_rule = "var_definition"
    expect(TYPE)
    identifier = scan(IDENTIFIER)
    AST::VarDefinition.new(variable: identifier)
  end

  def var_assignment
    @current_rule = "var_assignment"
    identifier = scan(IDENTIFIER)
    expect("=")
    value = expr
    AST::VarAssignment.new(variable: identifier, value: value)
  end

  def expr
    @current_rule = "expr"
    left = nil
    if scan(OPEN_PAREN)
      left = expr
      expect(CLOSE_PAREN)
    else
      left = if match?(INTEGER)
        AST::IVal.new(val: scan(INTEGER).to_i)
      elsif match?(IDENTIFIER)
        AST::VarReference.new(variable: scan(IDENTIFIER))
      elsif raise ScannerError, "expected INTEGER or IDENTIFIER"
      end
    end

    if match?(OP)
      op = scan(OP)
      right = expr

      AST::Expr.new(left: left, op: op, right: right)
    else
      left
    end
  end

  # scanner helpers

  def scan(needle)
    consume_whitespace
    @s.scan(needle)
  end

  def match?(needle)
    consume_whitespace
    @s.match?(needle)
  end

  def consume_whitespace
    @s.scan(/\s+/)
  end

  def expect(needle)
    match = scan(needle)

    raise ScannerError, "looking for #{needle}" if match.nil?
  end

  def eos?
    consume_whitespace
    @s.eos?
  end
end
