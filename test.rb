# frozen_string_literal: true

require "./app"
require "erb"

class TestHarness
  include AST
  def initialize(destination:)
    @destination = destination # destination dir

    @test_cases = []
  end

  def generate
    # populate @test_cases with expected output and ASM
    TestHarness.test_cases.each do |tc|
      public_send(tc)
    end

    # write out ASM
    @test_cases.each do |tc|
      File.open(scratch_file_path("#{tc[0]}.S"), "w") do |f|
        f.write(tc[2])
      end
    end

    # write out runner
    File.open(scratch_file_path("runner.c"), "w") do |f|
      f.write(runner_file_contents)
    end
  end

  def tc1 = expect(42, "42;")
  def tc2 = expect(64, "42 + 22;")
  def tc3 = expect(20, "40 / 2;")
  def tc4 = expect(50, "55 - 5;")
  def tc5 = expect(900, "10 * (45 * 2);")
  def tc6 = expect(900, "1 ;2 + 23 ; 22222; 10 * (45 * 2);")
  def tc7 = expect(44, "int a; int b ; a = 22; b = 11; a * 2;")
  def tc8 = expect(242, "int a; int b ; a = 22; b = 11; a * b;")
  def tc9 = expect(24, "int a; int b ; a = 22; b = a; b + 2;")
  def tc10 = expect(267, "int a; a = 22; int b ; b = ((a * 12) + 1); b + 2;")
  def tc11 = expect(11, "fn abc { 2 * 5; } abc() + 1;")
  def tc12 = expect(11, "int c; c = def() ; fn def { 2 * 5; } c + 1;")

  private

  def scratch_file_path(file)
    File.join(@destination, file)
  end

  def runner_file_contents
    template = ERB.new(<<~EOF, trim_mode: "%>")
      /* GENERATED AT <%= Time.now %> */
      <% @test_cases.each do |tc| %>
      int <%= tc[0] %>();
      <% end %>

      void run_test(int (*sut)(), int expected, const char *name);

      void run_tests()
      {
          <% @test_cases.each do |tc| %>
          run_test(<%= tc[0] %>, <%= tc[1] %>, "<%= tc[0] %>");
          <% end %>
      }
    EOF

    template.result(binding)
  end

  def expect(expected, expr)
    fn = caller_locations(1, 1)[0].label
    @test_cases << [fn, expected, Minicomp.new(fn).compile(expr)]
  end

  class << self
    def test_cases
      public_instance_methods(false).filter { _1.to_s.start_with?("tc") }
    end
  end
end
