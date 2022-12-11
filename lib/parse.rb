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
    expr
  end

  private

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

  def require(needle)
    match = scan(needle)

    raise ScannerError if match.nil?
  end

  def expr
    left = nil
    if scan(OPEN_PAREN)
      left = expr
      require(CLOSE_PAREN)
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
end
