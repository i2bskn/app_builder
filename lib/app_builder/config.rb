module AppBuilder
  class Config
    CHANGEABLE_PARAMETERS = [
      :build_host,
      :build_user,
      :build_ssh_options,
      :build_id,
      :project_name,
      :remote_repository,
      :branch,
      :revision,
      :src_base_url,
      :manifest_base_url,
      :builded_src_ext,
      :manifest_ext,
      :remote_src_path,
      :remote_manifest_path,
      :manifest_template_path,
      :resource_host,
      :resource_user,
      :resource_ssh_options,
      :logger,
    ].freeze

    PARAMETERS = [
      :working_path,
      :repo_path,
      :archive_path,
      :build_path,
      :builded_src_path,
      :builded_manifest_path,
      :revision_path,
      :src_url,
      :manifest_url,
      :remote_app_home,
    ].concat(CHANGEABLE_PARAMETERS).freeze

    attr_accessor *CHANGEABLE_PARAMETERS

    def initialize(options = {})
      reset
      merge(options)
    end

    def merge(params)
      params.each do |key, value|
        self.send("#{key}=", value)
      end
      self
    end

    def build_name
      [build_id, builded_src_ext].join(".")
    end

    def manifest_name
      [build_id, manifest_ext].join(".")
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

    def builded_manifest_path
      File.join(build_path, manifest_name)
    end

    def revision_path
      File.join(archive_path, "revision.yml")
    end

    def src_url
      File.join(src_base_url, build_name)
    end

    def manifest_url
      File.join(manifest_base_url, manifest_name)
    end

    def remote_app_home
      File.join("/var/www", project_name)
    end

    def reset
      @build_host             = "localhost"
      @build_user             = ENV.fetch("USER", nil)
      @build_ssh_options      = {}
      @build_id               = Time.now.strftime("%Y%m%d%H%M%S")
      @project_name           = File.basename(`git rev-parse --show-toplevel`.chomp)
      @remote_repository      = `git remote get-url origin`.chomp
      @branch                 = ENV.fetch("TARGET_BRANCH", "master")
      @revision               = `git rev-parse #{branch}`.chomp
      @builded_src_ext        = "tar.gz"
      @manifest_ext           = "yml"
      @manifest_template_path = File.expand_path("template/manifest.yml.erb", __dir__)
      @resource_user          = build_user
      @resource_ssh_options   = build_ssh_options
      @logger                 = Logger.new(STDOUT)
    end
  end
end
