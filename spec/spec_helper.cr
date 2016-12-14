require "../src/microtest"

include Microtest::DSL

macro microtest_test(&block)
  {%
    c = <<-CRYSTAL
      require "../src/microtest"

      include Microtest::DSL

      describe Microtest do
        #{block.body.id}
      end

      Microtest.run!([
        Microtest::JsonSummaryReporter.new
      ] of Microtest::Reporter)
    CRYSTAL
  %}

  output = IO::Memory.new

  s = Process.run("crystal", ["eval", {{c}}], output: output)

  begin
    res = JSON.parse(output.to_s)
  rescue e
    puts "Error parsing JSON:"
    p output.to_s
    raise e
  end
end

macro reporter_test(reporters, &block)
  {%
    c = <<-CRYSTAL
      require "../src/microtest"

      include Microtest::DSL

      describe Microtest do
        #{block.body.id}
      end

      Microtest.run!(#{reporters} of Microtest::Reporter)
    CRYSTAL
  %}

  output = IO::Memory.new

  s = Process.run("crystal", ["eval", {{c}}], output: output)

  output.to_s
end

Microtest.run!([
  Microtest::DescriptionReporter.new,
  Microtest::ErrorListReporter.new,
  Microtest::SlowTestsReporter.new,
  Microtest::SummaryReporter.new,
] of Microtest::Reporter)
