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
      execute_with_hooks(:archive) do
        execute("git archive #{branch} | tar -x -C #{archive_path}", chdir: repo_path)
        create_revision_to(revision_path)
      end
    end
  end
end
