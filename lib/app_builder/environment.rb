module AppBuilder
  class Environment
    attr_accessor :name
    attr_reader :repo_path, :branch, :source_path, :source_type

    def initialize(source_path, options = {})
      @name        = options[:name] || ENV.fetch("APP_ENV", "default")
      @repo_path   = options[:repo_path] || `git rev-parse --show-toplevel`.chomp
      @branch      = options[:branch] || ENV.fetch("TARGET_BRANCH", `git symbolic-ref --short HEAD`.chomp)
      @source_path = source_path
      @source_type = options.fetch(:source_type, :git) # :git (git show branch:path) or :path (File.read(path))
    end

    def create_file(template_path, output_path)
      File.open(output_path, "w") do |f|
        f.write(ERB.new(File.read(template_path), nil, "-").result(binding))
      end
    end

    def [](key)
      hash.fetch(key.to_s, nil)
    end

    def to_hash
      raw_source.fetch(name.to_s)
    end
    alias :hash :to_hash

    def raw_source
      @source ||= load_source
    end

    private

      def load_source
        case source_type
        when :git
          raw_src = Dir.chdir(repo_path) { `git show #{branch}:#{source_path}` }
        when :path
          raw_src = File.read(source_path)
        else
          raise "Unknown source_type: #{source_type}"
        end

        YAML.load(ERB.new(raw_src, nil, "-").result(binding))
      end

      def method_missing(name, *args, &block)
        super unless hash.has_key?(name.to_s)

        hash.fetch(name.to_s)
      end

      def respond_to_missing?(name, include_private = false)
        hash.has_key?(name.to_s)
      end
  end
end
