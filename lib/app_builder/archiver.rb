module AppBuilder
  class Archiver < Base
    class << self
      def archive(conf)
        new(conf).archive
      end
    end

    def archive
      create_base_directories
      update_repository
      Array(before_archive).each { |hook| hook.call(self) }
      execute("git archive #{branch} | tar -x -C #{archive_path}", chdir: repo_path)
      create_revision_to(revision_path)
      Array(after_archive).each { |hook| hook.call(self) }
    end
  end
end
