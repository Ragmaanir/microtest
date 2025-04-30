require "ecr"
require "yaml"
require "./version"
require "../../spec/helpers"

case ARGV[0]?
when "readme"
  GenerateReadmeCommand.new.call
when "release"
  ReleaseCommand.new.call
else
  raise "Commands are 'readme' or 'release'"
end

abstract class Command
  def confirm(msg : String)
    print "❓ #{msg} [y/n/yes/no]: "

    while a = gets.not_nil!.strip.downcase
      case a
      when "y", "yes" then break
      when "n", "no"  then exit
      end
    end
  end

  def run(cmd, args = [] of String, msg = "Command failed: #{cmd} #{args.join(" ")}")
    puts "Running: #{cmd} #{args.join(" ")}"

    s = Process.run(
      cmd,
      args,
      output: Process::Redirect::Inherit,
      error: Process::Redirect::Inherit
    )

    abort(msg) unless s.success?
  end
end

class GenerateReadmeCommand < Command
  class Readme
    def image(asset_name : String)
      generate_image_from_html(asset_name)
      file = "assets/#{asset_name}.jpg"
      raise "Image does not exist: #{file}" unless File.exists?(file)
      "![missing](#{file}?raw=true)"
    end

    def generate_image_from_html(asset_name : String)
      Helpers.run_in_docker(%[wkhtmltoimage --width 800 /root/#{asset_name}.html /root/#{asset_name}.jpg])
      # remove metadata
      Helpers.run_in_docker(%[exiftool -all= -overwrite_original /root/#{asset_name}.jpg])

      Helpers.fix_asset_permissions("#{asset_name}.jpg")
    end

    ECR.def_to_s "README.md.ecr"
  end

  def call
    puts "🔬 Build #{Helpers::DOCKER_IMAGE_NAME} docker image " \
         "(aha, wkhtmltoimage, exiftool)" \
         " to convert terminal output to html and then to jpg"

    Helpers.build_docker_image

    puts "🔬 Running crystal tool format --check"
    run("crystal", ["tool", "format", "--check"])

    puts "🔬 Running tests"
    Helpers.run_and_record_specs

    puts "🔬 Generating README.md from README.md.ecr"
    File.write("README.md", Readme.new.to_s)
  end
end

class ReleaseCommand < Command
  def call
    run("crystal", ["spec"])

    # TODO: make it pass
    # run("./bin/ameba")
    run("./cli", ["readme"])
    run("git", ["add", "README.md"])
    run("git", ["add", "-A", "./assets"])

    confirm("Did you update CHANGLEOG.md?")

    run("git", ["status"])
    confirm("Does commit look ok?")

    version_name = "v#{Microtest::VERSION}"

    puts "🔬 Releasing version #{version_name}"
    run("git", ["commit", "-m", "Version #{version_name}"])
    run("git", ["tag", version_name])
    run("git", ["push"])
    run("git", ["push", "gh", version_name])
  end
end
