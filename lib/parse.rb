# frozen_string_literal: true

require "./lib/ast"
require "strscan"

class Parser
  class ScannerError < StandardError; end

  def initialize(input)
    @s = StringScanner.new(input)
  end

  INTEGER = /\d+/
  OPEN_PAREN = /\(/
  CLOSE_PAREN = /\)/
  OP = %r{[+*/-]}

  def parse
    statement_list
  end

  private

  # production rules

  def statement_list
    statements = []

    statements << statement until eos?
    statements
  end

  def statement
    ret = expr
    expect(";")
    ret
  end

  def expr
    left = nil
    if scan(OPEN_PAREN)
      left = expr
      expect(CLOSE_PAREN)
    else
      left = AST::IVal.new(val: scan(INTEGER).to_i)
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

    raise ScannerError if match.nil?
  end

  def eos?
    consume_whitespace
    @s.eos?
  end
end
