module AppBuilder
  class Environment
    attr_accessor :name, :source

    def initialize(name, source)
      @name   = name
      @source = source
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
  end
end
