module AppBuilder
  class Environment
    attr_accessor :name
    attr_reader :repo_path, :branch, :source_path

    def initialize(source_path, options = {})
      @name        = options[:name] || ENV.fetch("APP_ENV", "default")
      @repo_path   = options[:repo_path] || `git rev-parse --show-toplevel`.chomp
      @branch      = options[:branch] || ENV.fetch("TARGET_BRANCH", `git symbolic-ref --short HEAD`.chomp)
      @source_path = source_path
      @from_branch = options.fetch(:from_branch, true)
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
      @source ||= load_source
    end

    private

      def load_source
        if from_branch
          YAML.load(
            ERB.new(
              Dir.chdir(repo_path) {
                `git show #{branch}:#{source_path}`
              }
            ).result(binding)
          )
        else
          YAML.load_file(source_path)
        end
      end
  end
end
