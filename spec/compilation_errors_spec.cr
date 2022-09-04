require "./spec_helper"

describe CompilationErrors do
  test "empty describe block compiles" do
    result = record_test_json do
      describe C do
      end
    end

    assert result.success?
  end

  test "empty test name does not compile" do
    result, _stdout, stderr = run_block do
      describe C do
        test "" do
        end
      end
    end

    assert !result.success?
    assert stderr.to_s.matches?(%r{Test name cant be empty in .*:\d+})
  end

  test "duplicate describe does not compile" do
    result, _stdout, stderr = run_block do
      describe C do
      end

      describe C do
      end
    end

    assert !result.success?
    assert stderr.to_s.includes?("Duplicate describe for: C")
  end

  test "duplicate test does not compile" do
    result, _stdout, stderr = run_block do
      describe C do
        test "a" do
        end

        test "a"
      end
    end

    assert !result.success?
    assert stderr.to_s.includes?("Test method with same name already defined: test__a (\"a\")")
  end
end
