require "./spec_helper"

describe Microtest do
  test "power asserts" do
    assert true == !false
    assert 1 > 0
  end

  test "succeeds" do
    a = 1
    bob = 5

    assert bob == 4 + a
  end

  test "valid test-name" do
    assert true
  end

  test "assert_raises" do
    assert_raises(ArgumentError) do
      raise ArgumentError.new("bob")
    end

    assert_raises(Microtest::AssertionFailure) do
      assert_raises(ArgumentError) do
      end
    end

    assert_raises(Microtest::AssertionFailure) do
      assert_raises(ArgumentError) do
        raise "unexpected exception"
      end
    end
  end

  test "test results" do
    result = microtest_test do
      test "assertion failure message" do
        a = 2
        assert 2**4 == a * a * a
      end

      test "long assertion failure message" do
        long_name = 2
        assert 2**4 == long_name + long_name + long_name
      end

      test "hide literals in failure message" do
        assert "left" == "right"
      end

      test "skip this" do
        skip "this is pending"
      end

      test "pending"

      pending "pending too" do
        raise ""
      end

      test "raise" do
        raise "something"
      end
    end

    exc = result["MicrotestTest#assertion_failure_message"]["exception"].as_s

    assert uncolor(exc) == <<-EXC
    assert (2 ** 4) == ((a * a) * a) # false
    ==================================================
    2 ** 4                   => 16
    a                        => 2
    a * a                    => 4
    (a * a) * a              => 8
    EXC

    exc = result["MicrotestTest#long_assertion_failure_message"]["exception"].as_s

    assert uncolor(exc) == <<-EXC
    assert (2 ** 4) == ((long_name + long_name) + long_name) # false
    ==================================================
    2 ** 4
    16
    --------------------------------------------------
    long_name
    2
    --------------------------------------------------
    long_name + long_name
    4
    --------------------------------------------------
    (long_name + long_name) + long_name
    6
    --------------------------------------------------
    EXC

    exc = result["MicrotestTest#hide_literals_in_failure_message"]["exception"].as_s

    assert uncolor(exc) == %(assert "left" == "right" # false\n)

    assert result["MicrotestTest#skip_this"]["type"] == "Microtest::TestSkip"
    assert result["MicrotestTest#pending"]["type"] == "Microtest::TestSkip"
    assert result["MicrotestTest#pending_too"]["type"] == "Microtest::TestSkip"
    assert result["MicrotestTest#raise"]["type"] == "Microtest::TestFailure"
  end

  test "progress reporter" do
    result = reporter_test([Microtest::ProgressReporter.new]) do
      test "success" do
        assert true == true
      end

      test "failure" do
        assert 3 > 5
      end

      test "skip" do
        skip "skip this one"
      end
    end

    dot = Microtest::ProgressReporter::CHARS[:dot][0]

    assert result.includes?(dot.colorize(:red).to_s)
    assert result.includes?(dot.colorize(:yellow).to_s)
    assert result.includes?(dot.colorize(:green).to_s)
  end

  test "focusing" do
    result = microtest_test do
      test "in focus", :focus do
        assert true
      end

      test "not in focus" do
        assert false
      end
    end

    assert result["MicrotestTest#in_focus"]["type"] == "Microtest::TestSuccess"
    assert !result.as_h.has_key?("MicrotestTest#not_in_focus")
  end

  test "before and after hook" do
    result = full_microtest_test do
      describe Microtest do
        before do
          @@value = true
        end

        after do
          assert @@value == false
        end

        test "first" do
          assert @@value == true
          @@value = false
        end

        test "second" do
          assert @@value == true
          @@value = false
        end
      end
    end

    assert result["MicrotestTest#first"]["type"] == "Microtest::TestSuccess"
    assert result["MicrotestTest#second"]["type"] == "Microtest::TestSuccess"
  end

  test "around hook" do
    skip "crashes in power assert formatter when specific combination of tests is run"
    result = microtest_test do
      around do |block|
        @@value = true
        block.call
        assert @@value == false
      end

      test "first" do
        assert @@value == true
        @@value = false
      end

      test "second" do
        assert @@value == true
        @@value = false
      end
    end

    assert result["MicrotestTest#first"]["type"] == "Microtest::TestSuccess"
    assert result["MicrotestTest#second"]["type"] == "Microtest::TestSuccess"
  end
end

# Make sure an empty describe block compiles
describe Array do
end
