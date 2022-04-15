require "./spec_helper"

describe CompilationErrors do
  test "empty describe block compiles" do
    result = record_test_json do
      describe C do
      end
    end

    assert result.success?
  end

  test "duplicate describe does not compile" do
    result, stdout, stderr = run_block do
      describe C do
      end

      describe C do
      end
    end

    assert !result.success?
    assert stderr.to_s.includes?("Duplicate describe for: C")
  end
end
