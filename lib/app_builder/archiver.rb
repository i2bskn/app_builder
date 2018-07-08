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

      rev_hash = { "branch" => branch, "revision" => revision }
      File.open(revision_path, "w") { |f| f.write(rev_hash.to_yaml) }
      log(:info, "Create revision: #{rev_hash.inspect}")
    end
  end
end
