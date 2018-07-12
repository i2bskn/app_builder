module AppBuilder
  class Uploader < Base
    attr_accessor :builder

    class << self
      def upload(conf)
        new(conf).upload
      end
    end

    def initialize(conf = nil)
      case conf
      when Archiver
        @builder = Builder.new(conf)
        conf = conf.config
      when Builder
        @builder = conf
        conf = conf.config
      end
      super(conf)
      @builder ||= Builder.new(config)
    end

    def upload
      upload_proc = s3? ? method(:upload_to_s3) : method(:upload_to_server)
      builder.build
      execute_with_hooks(:upload) do
        upload_proc.call(builded_src_path, remote_src_file)
        generate_manifest
        upload_proc.call(builded_manifest_path, remote_manifest_file)
      end
    end

    def upload_to_s3(local, remote)
      log(:info, "Upload #{local} to #{src_url}")
      s3_client.put_object(
        bucket: upload_id,
        key:    remote,
        body:   File.open(local),
      )
    end

    def upload_to_server(local, remote)
      log(:info, "Upload #{local} to #{src_url}")
      resource_server.upload(local, remote)
    end

    def generate_manifest
      checksum = `openssl sha256 #{builded_src_path} | awk -F"=" '{ print $2 }'`.strip
      manifest = ERB.new(File.read(manifest_template_path)).result(binding)
      File.open(builded_manifest_path, "w") { |f| f.write(manifest) }
    end

    private

      def s3?
        upload_type == :s3
      end

      def s3_client
        @s3_client ||= Aws::S3::Client.new(
          region:        region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        )
      end

      def resource_server
        @resource_server ||= Server.new(
          resource_host,
          user:    resource_user,
          options: resource_ssh_options,
          logger:  logger
        )
      end
  end
end
