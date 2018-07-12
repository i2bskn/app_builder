module AppBuilder
  class Environment
    attr_accessor :name
    attr_reader :source_path

    def initialize(name, source_path)
      @name        = name
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

    def source
      @source ||= YAML.load_file(source_path)
    end
  end
end
