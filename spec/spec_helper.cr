require "../src/microtest"
require "./helpers"

include Microtest::DSL
include Helpers

COLOR_REGEX = %r{\e\[\d\d?(;\d)?m}

def uncolor(str)
  str.gsub(COLOR_REGEX, "")
end

macro microtest_test(&block)
  {%
    c = <<-CRYSTAL
      require "./src/microtest"

      include Microtest::DSL

      #{block.body.id}

      Microtest.run!([
        Microtest::JsonSummaryReporter.new
      ] of Microtest::Reporter)
    CRYSTAL
  %}

  output = IO::Memory.new

  s = Process.run("crystal", ["eval", {{c}}, "--error-trace"], output: output, error: STDERR)

  begin
    MicrotestJsonResult.new(s, JSON.parse(output.to_s))
  rescue e
    raise "Error parsing JSON: #{output.to_s.inspect}"
  end
end

macro reporter_test(reporters, &block)
  {%
    c = <<-CRYSTAL
      require "./src/microtest"

      include Microtest::DSL

      #{block.body.id}

      Microtest.run!(#{reporters} of Microtest::Reporter)
    CRYSTAL
  %}

  output = IO::Memory.new
  err = IO::Memory.new

  s = Process.run("crystal", ["eval", {{c}}, "--error-trace"], output: output, error: err)

  MicrotestStdoutResult.new(s, output.to_s, err.to_s)
end

def generate_assets?
  ENV.has_key?("ASSETS")
end

Microtest.run!
