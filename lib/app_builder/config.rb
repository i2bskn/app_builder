module AppBuilder
  class Config
    CHANGEABLE_PARAMETERS = [
      :build_id,             # default: timestamp
      :project_name,         # default: repository name
      :remote_repository,    # default: remote origin
      :branch,               # default: TARGET_BRANCH or master
      :revision,             # default: commit hash
      :resource_type,        # :s3 or :http or :https (default: :s3)
      :upload_id,            # bucket name or remote host (default: none)
      :remote_app_home_base, # default: /var/www
      :keep_release,         # default: 5
      :logger,               # default: AppBuilder::Logger

      # hooks
      :before_archive,
      :after_archive,
      :before_build,
      :after_build,
      :before_upload,
      :after_upload,

      # source
      :remote_src_path, # default: assets

      # manifest
      :manifest_template_path, # default: lib/app_builder/template/manifest.yml.erb in this repository
      :remote_manifest_path,   # default: manifests

      # Only use when upload to S3
      :region,
      :access_key_id,
      :secret_access_key,

      # Only use when upload with scp
      :resource_host,
      :resource_user,
      :resource_ssh_options,
      :resource_document_root,
    ].freeze

    PARAMETERS = [
      :working_path,
      :repo_path,
      :archive_path,
      :build_path,
      :builded_src_path,
      :builded_manifest_path,
      :revision_path,
      :remote_src_file,
      :remote_manifest_file,
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
      "#{build_id}.tar.gz"
    end

    def manifest_name
      "#{build_id}.yml"
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

    def remote_src_file
      File.join(remote_src_path, build_name)
    end

    def remote_manifest_file
      File.join(remote_manifest_path, manifest_name)
    end

    def src_url
      uploaded_url(remote_src_file)
    end

    def manifest_url
      uploaded_url(remote_manifest_file)
    end

    def remote_app_home
      File.join(remote_app_home_base, project_name)
    end

    def uploaded_url(path)
      "#{resource_type.to_s}://#{File.join(upload_id, path)}"
    end

    def reset
      @build_id               = Time.now.strftime("%Y%m%d%H%M%S")
      @project_name           = File.basename(`git rev-parse --show-toplevel`.chomp)
      @remote_repository      = `git remote get-url origin`.chomp
      @branch                 = ENV.fetch("TARGET_BRANCH", "master")
      @revision               = `git rev-parse #{branch}`.chomp
      @remote_src_path        = "assets"
      @manifest_template_path = File.expand_path("template/manifest.yml.erb", __dir__)
      @remote_manifest_path   = "manifests"
      @resource_user          = ENV.fetch("USER", nil)
      @resource_ssh_options   = {}
      @remote_app_home_base   = "/var/www"
      @logger                 = Logger.new(STDOUT)
      @resource_type          = :s3
      @keep_release           = 5

      # for upload to S3 (from `.aws/config` and `.aws/credentials`)
      @region            = ENV.fetch("AWS_DEFAULT_REGION", aws_config("region") || "ap-northeast-1")
      @access_key_id     = ENV.fetch("AWS_ACCESS_KEY_ID", aws_credential("aws_access_key_id"))
      @secret_access_key = ENV.fetch("AWS_SECRET_ACCESS_KEY", aws_credential("aws_secret_access_key"))

      initialize_hooks
    end

    private

      def initialize_hooks
        [
          :@before_archive,
          :@after_archive,
          :@before_build,
          :@after_build,
          :@before_upload,
          :@after_upload,
        ].each { |hook_name| instance_variable_set(hook_name, []) }
      end

      def aws_config(key)
        find_aws_setting_by(
          ENV.fetch("AWS_CONFIG_FILE", File.expand_path("~/.aws/config")),
          key,
        )
      end

      def aws_credential(key)
        find_aws_setting_by(
          ENV.fetch("AWS_CREDENTIAL_FILE", File.expand_path("~/.aws/credentials")),
          key,
        )
      end

      def find_aws_setting_by(path, key)
        return nil unless File.exist?(path)
        File.readlines(path).detect { |line|
          line.start_with?(/\A\s*#{key}/)
        }&.split("=")&.last&.strip
      end
  end
end
