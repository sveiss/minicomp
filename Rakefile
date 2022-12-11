# frozen_string_literal: true

require "bundler/setup"
require "./app"
require "./test"

def test_asm_files = TestHarness.test_cases.map { "scratch/#{_1}.S" }
TestHarness.new(destination: "scratch").generate

test_asm_files.each { file _1 }

file "scratch/harness" => ["harness.c", "scratch/runner.c"] + test_asm_files do |t|
  sh "cc -o #{t.name} #{t.prerequisites.join(" ")}"
end

task test: "scratch/harness" do
  sh "scratch/harness"
end

task default: [:test]
