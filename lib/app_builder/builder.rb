module AppBuilder
  class Builder < Base
    class << self
      def build(config)
        new(config).build
      end
    end

    def build
      archiver.archive
      execute("tar zcf #{builded_src_path} .", chdir: archive_path)
    end

    def archiver
      @archiver ||= Archiver.new(config)
    end
  end
end
