require "./spec_helper"

describe MicrotestHooks do
  test "before and after hook" do
    result = record_test_json do
      {{ read_file("#{__DIR__}/hook_examples/before_and_after_hooks.cr").id }}
    end

    assert result.success?

    results = result.json["results"]

    assert results["HooksTest#first"]["type"] == "Microtest::TestSuccess"
    assert results["HooksTest#second"]["type"] == "Microtest::TestSuccess"
  end

  test "error in before hook" do
    result = record_test_json do
      describe Hooks do
        before do
          raise "Raised exception"
        end

        test "failing test" do
          assert false
        end
      end
    end

    assert !result.success?
    assert !result.status.success?

    assert result.json["success"] == false
    assert result.json["aborted"] == true

    a = result.json["abortion"]
    assert a["message"] == "Raised exception"
    assert a["suite"] == "HooksTest"
    assert a["test_name"] == "failing test"
    assert a["test_method"] == "test__failing_test"
    assert a["backtrace"].as_a.any?(&.as_s.includes?("before_hooks"))

    assert result.json["results"].as_h.size == 1
    assert result.json["results"]["HooksTest#failing_test"]["type"] == "Microtest::TestAbortion"
  end

  test "error in after hook" do
    result = record_test_json do
      describe Hooks do
        before do
          @value = true
        end

        after do
          raise "Raised exception"
        end

        test "failing test" do
          assert @value == true
        end
      end
    end

    assert !result.success?
    assert !result.status.success?
    assert result.json["success"] == false
    assert result.json["aborted"] == true

    a = result.json["abortion"]
    assert a["message"] == "Raised exception"
    assert a["suite"] == "HooksTest"
    assert a["test_name"] == "failing test"
    assert a["test_method"] == "test__failing_test"
    assert a["backtrace"].as_a.any?(&.as_s.includes?("after_hooks"))

    assert result.json["results"]["HooksTest#failing_test"]["type"] == "Microtest::TestSuccess"
  end

  test "around hook" do
    result = record_test_json do
      {{ read_file("#{__DIR__}/hook_examples/around_hook.cr").id }}
    end

    assert result.json["results"]["AroundHookTest#first"]["type"] == "Microtest::TestSuccess"
    assert result.json["results"]["AroundHookTest#second"]["type"] == "Microtest::TestSuccess"
  end

  test "hook orders" do
    # NOTE: The test has to be in a separate file because it has yield in it
    # and crystal would interpret the yield as belonging to the test method, which makes
    # it fail to compile because that parameter would be missing.
    result = record_test do
      {{ read_file("#{__DIR__}/hook_examples/hook_order.cr").id }}
    end

    assert result.success?
    assert result.stdout == <<-ORDER
    Microtest.around:start
    Test.around:start
    Microtest.before
    Test.before
    Test.test
    Test.after
    Microtest.after
    Test.around:end
    Microtest.around:end

    ORDER
  end
end
