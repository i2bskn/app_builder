module AppBuilder
  class Builder < Base
    attr_accessor :archiver

    class << self
      def build(conf)
        new(conf).build
      end
    end

    def initialize(conf = nil)
      if conf.class <= Archiver
        @archiver = conf
        conf = conf.config
      end
      super(conf)
      @archiver ||= Archiver.new(config)
    end

    def build
      archiver.archive
      Array(before_build).each { |hook| hook.call(self) }
      execute("tar zcf #{builded_src_path} .", chdir: archive_path)
      Array(after_build).each { |hook| hook.call(self) }
    end
  end
end
