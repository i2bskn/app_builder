module AppBuilder
  class Environment
    attr_accessor :name
    attr_reader :repo_path, :branch, :source_path

    def initialize(source_path, name: nil, repo_path: nil, branch: nil)
      @name        = name || ENV.fetch("APP_ENV", "default")
      @repo_path   = repo_path || `git rev-parse --show-toplevel`.chomp
      @branch      = branch || ENV.fetch("TARGET_BRANCH", `git symbolic-ref --short HEAD`.chomp)
      @source_path = source_path
    end

    def create_file(template_path, output_path)
      File.open(output_path, "w") do |f|
        f.write(ERB.new(File.read(template_path)).result(template_binding))
      end
    end

    def template_binding
      env = source.fetch(name.to_s)
      Class.new.tap { |klass|
        klass.define_method(:env) { env }
      }.instance_eval { binding }
    end

    def [](key)
      hash.fetch(key.to_s, nil)
    end

    def to_hash
      source.fetch(name.to_s)
    end
    alias :hash :to_hash

    def source
      @source ||= YAML.load(
        ERB.new(
          Dir.chdir(repo_path) {
            `git show #{branch}:#{source_path}`
          }
        ).result(binding)
      )
    end
  end
end
