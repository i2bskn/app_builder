module AppBuilder
  class Builder < Base
    def build
      archiver.archive
      execute("tar zcf #{File.join(build_path, 'app.tar.gz')} .", chdir: archive_path)
    end

    def archiver
      @archiver ||= Archiver.new(config)
    end
  end
end
