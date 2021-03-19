require "json"

module Helpers
  class MicrotestJsonResult
    getter status : Process::Status
    getter json : JSON::Any

    def initialize(@status, @json)
    end

    def success?
      status.success? && json["success"] == true && json["aborted"] == false
    end
  end

  class MicrotestStdoutResult
    getter status : Process::Status
    getter stdout : String
    getter stderr : String

    def initialize(@status, @stdout, @stderr)
    end

    def success?
      status.success?
    end

    def to_s(io : IO)
      if success?
        io << stdout
      else
        io << stderr
        io << stdout
      end
    end
  end

  # convert text via "aha" to html
  def self.save_console_output(result : MicrotestStdoutResult, target : String, title = "", bg = "black")
    escaped = Process.quote(result.to_s)

    run_in_docker(%[echo #{escaped} | aha --#{bg} --title "#{title}" > /root/#{target}.html])

    fix_asset_permissions("#{target}.html")
  end

  def self.fix_asset_permissions(file : String)
    ownership = `stat -c "%u:%g" assets`.strip

    system(%[sudo chown "#{ownership}" assets/#{file}])
  end

  def self.run_and_record_specs
    output = IO::Memory.new
    err = IO::Memory.new

    s = Process.run("crystal", ["spec"], {"ASSETS" => "true"}, output: output, error: err)

    result = MicrotestStdoutResult.new(s, output.to_s, err.to_s)

    puts output.to_s

    save_console_output(result, "spec")
  end

  DOCKER_IMAGE_NAME = "microtest-utils"

  def self.build_docker_image
    system("sudo", ["docker", "build", ".", "-t", DOCKER_IMAGE_NAME])
  end

  def self.run_in_docker(cmd : String)
    system("sudo", [
      "docker", "run", "-v", "#{Dir.current}/assets:/root/",
      DOCKER_IMAGE_NAME,
      "/bin/sh", "-c",
      cmd,
    ]) || raise("Failed: #{cmd}")
  end
end
