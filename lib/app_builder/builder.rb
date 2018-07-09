module AppBuilder
  class Builder < Base
    def build
      archiver.archive
      execute("tar zcf #{builded_src_path} .", chdir: archive_path)
    end

    def archiver
      @archiver ||= Archiver.new(config)
    end
  end
end
