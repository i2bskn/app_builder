module AppBuilder
  class Config
    VALID_OPTIONS = [
      :build_id,
      :project_name,
      :remote_repository,
      :target_branch,
      :working_path,
      :repo_path,
      :archive_path,
      :build_path,
      :logger,
    ].freeze

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

    def reset
      self.build_id          = Time.now.strftime("%Y%m%d%H%M%S")
      self.project_name      = File.basename(`git rev-parse --show-toplevel`.chomp)
      self.remote_repository = `git remote get-url origin`.chomp
      self.branch            = ENV.fetch("TARGET_BRANCH", "master")
      self.working_path      = File.join("/var/tmp", project_name)
      self.repo_path         = File.join(working_path, "repo")
      self.archive_path      = File.join(working_path, "archive", build_id)
      self.build_path        = File.join(working_path, "build", build_id)
      self.logger            = Logger.new(STDOUT)
    end
  end
end
