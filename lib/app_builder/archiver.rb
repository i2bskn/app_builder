module AppBuilder
  class Archiver < Base
    def archive
      execute("mkdir -p #{working_path} #{archive_path} #{build_path}")
      if File.exist?("#{repo_path}/HEAD")
        execute("git remote update", chdir: repo_path)
      else
        execute("git clone --mirror #{remote_repository} #{repo_path}")
      end

      execute("git archive #{branch} | tar -x -C #{archive_path}", chdir: repo_path)
    end
  end
end
