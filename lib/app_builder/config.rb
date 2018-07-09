module AppBuilder
  class Config
    VALID_OPTIONS = [
      :build_id,
      :project_name,
      :remote_repository,
      :branch,
      :revision,
      :remote_src_path,
      :remote_manifest_path,
      :resource_host,
      :ssh_user,
      :identity_file,
      :logger,
    ].freeze

    PARAMETERS = [
      :working_path,
      :repo_path,
      :archive_path,
      :build_path,
      :builded_src_path,
      :revision_path,
    ].concat(VALID_OPTIONS).freeze

    attr_accessor *VALID_OPTIONS

    def initialize
      reset
    end

    def merge(params)
      params.each do |key, value|
        self.send("#{key}=", value)
      end
      self
    end

    def build_name
      "#{build_id}.tar.gz"
    end

    def working_path
      File.join("/var/tmp", project_name)
    end

    def repo_path
      File.join(working_path, "repo")
    end

    def archive_path
      File.join(working_path, "archive", build_id)
    end

    def build_path
      File.join(working_path, "build", build_id)
    end

    def builded_src_path
      File.join(build_path, build_name)
    end

    def revision_path
      File.join(archive_path, "revision.yml")
    end

    def reset
      @build_id          = Time.now.strftime("%Y%m%d%H%M%S")
      @project_name      = File.basename(`git rev-parse --show-toplevel`.chomp)
      @remote_repository = `git remote get-url origin`.chomp
      @branch            = ENV.fetch("TARGET_BRANCH", "master")
      @revision          = `git rev-parse #{branch}`.chomp
      @ssh_user          = ENV.fetch("USER", nil)
      @identity_file     = "~/.ssh/id_rsa"
      @logger            = Logger.new(STDOUT)
    end
  end
end
