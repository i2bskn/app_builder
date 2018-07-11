module AppBuilder
  class Config
    CHANGEABLE_PARAMETERS = [
      :build_id,
      :project_name,
      :remote_repository,
      :branch,
      :revision,
      :upload_type,
      :upload_id, # bucket name or remote host
      :logger,

      # source
      :builded_src_ext,
      :remote_src_path,

      # manifest
      :manifest_template_path,
      :remote_manifest_path,
      :manifest_ext,

      # Only use when upload to S3
      :region,
      :access_key_id,
      :secret_access_key,

      # Only use when upload with scp
      :resource_host,
      :resource_user,
      :resource_ssh_options,

      # Only use when remote build
      # :build_host,
      # :build_user,
      # :build_ssh_options,
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

    def remote_src_file
      File.join(remote_src_path, build_name)
    end

    def remote_manifest_file
      File.join(remote_manifest_path, manifest_name)
    end

    def src_url
      "#{upload_type.to_s}://#{File.join(upload_id, remote_src_path, build_name)}"
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
      @resource_user          = @build_user
      @resource_ssh_options   = {}
      @logger                 = Logger.new(STDOUT)
      @upload_type            = :s3

      # for upload to S3
      @region = ENV.fetch("AWS_DEFAULT_REGION", aws_config("region") || "ap-northeast-1")
      @access_key_id = ENV.fetch("AWS_ACCESS_KEY_ID", aws_credential("aws_access_key_id"))
      @secret_access_key = ENV.fetch("AWS_SECRET_ACCESS_KEY", aws_credential("aws_secret_access_key"))
    end

    private

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
