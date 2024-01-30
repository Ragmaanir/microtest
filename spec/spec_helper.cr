require "../src/microtest"
require "./helpers"

include Microtest::DSL
include Helpers

SPEC_ROOT   = __DIR__
COLOR_REGEX = %r{\e\[\d\d?(;\d+)*m}

def uncolor(str)
  str.gsub(COLOR_REGEX, "")
end

def generate_assets?
  ENV.has_key?("ASSETS")
end

macro run_block(&block)
  {%
    c = <<-CRYSTAL
      require "../src/microtest"

      include Microtest::DSL

      #{block.body.id}

      Microtest.run!([
        Microtest::JsonSummaryReporter.new
      ] of Microtest::Reporter)
    CRYSTAL
  %}

  %stdout = IO::Memory.new
  %stderr = IO::Memory.new
  %input = IO::Memory.new({{c}})

  %result = Process.run(
    "crystal", ["run", "--no-color", "--no-codegen", "--error-trace", "--stdin-filename", "#{SPEC_ROOT}/test.cr"],
    input: %input, output: %stdout, error: %stderr
  )

  { %result, %stdout, %stderr}
end

macro record_test_json(seed = 1, &block)
  result = record_test([Microtest::JsonSummaryReporter.new] of Microtest::Reporter, {{seed}}) {{block}}

  begin
    MicrotestJsonResult.new(result.status, JSON.parse(result.stdout.to_s))
  rescue e
    raise "Error parsing JSON: #{result.stdout.to_s.inspect}"
  end
end

macro record_test(reporters = [] of Microtest::Reporter, seed = 1, &block)
  {%
    c = <<-CRYSTAL
      require "../src/microtest"

      include Microtest::DSL

      #{block.body.id}

      Microtest.run!(#{reporters})
    CRYSTAL
  %}

  %input = IO::Memory.new({{c}})
  %stdout = IO::Memory.new
  %stderr = IO::Memory.new

  %s = Process.run(
    "crystal", ["run", "--error-trace", "--stdin-filename", "#{SPEC_ROOT}/test.cr"],
    env: {"SEED" => {{seed}}.to_s},
    input: %input, output: %stdout, error: %stderr
  )

  raise "Error running tests: #{%stderr}" if !%stderr.empty?

  MicrotestStdoutResult.new(%s, %stdout.to_s, %stderr.to_s)
end

Microtest.run!
