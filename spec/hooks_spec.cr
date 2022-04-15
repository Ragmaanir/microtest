require "./spec_helper"

describe MicrotestHooks do
  test "before and after hook" do
    result = record_test_json do
      {{`cat spec/hook_examples/before_and_after_hooks.cr`}}
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
          raise "Before hook error"
        end

        test "first" do
          assert true == true
        end
      end
    end

    assert !result.success?
    assert !result.status.success?

    assert result.json["success"] == false
    assert result.json["aborted"] == true
    assert result.json["aborting_exception"] == "Error in hook: Before hook error"
    assert result.json["results"].as_h.size == 1
    assert result.json["results"]["HooksTest#first"]["type"] == "Microtest::TestSkip"
  end

  test "error in after hook" do
    result = record_test_json do
      describe Hooks do
        before do
          @value = true
        end

        after do
          raise "After hook error"
        end

        test "first" do
          assert @value == true
          @value = false
        end
      end
    end

    assert !result.success?
    assert !result.status.success?
    assert result.json["success"] == false
    assert result.json["aborted"] == true
    assert result.json["aborting_exception"] == "Error in hook: After hook error"
    assert result.json["results"]["HooksTest#first"]["type"] == "Microtest::TestSuccess"
  end

  test "around hook" do
    result = record_test_json do
      {{`cat spec/hook_examples/around_hook.cr`}}
    end

    assert result.json["results"]["AroundHookTest#first"]["type"] == "Microtest::TestSuccess"
    assert result.json["results"]["AroundHookTest#second"]["type"] == "Microtest::TestSuccess"
  end

  test "hook orders" do
    # NOTE: The test has to be in a separate file because it has yield in it
    # and crystal would interpret the yield as belonging to the test method, which makes
    # it fail to compile because that parameter would be missing.
    result = record_test do
      {{`cat spec/hook_examples/hook_order.cr`}}
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
