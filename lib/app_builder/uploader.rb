module AppBuilder
  class Uploader < Base
    def upload
      builder.build
      if s3?(src_url)
        upload_to_s3(builded_src_path, src_url)
      else
        upload_to_server(builded_src_path, remote_src_path)
      end

      generate_manifest
      if s3?(manifest_url)
        upload_to_s3(builded_manifest_path, manifest_url)
      else
        upload_to_server(builded_manifest_path, remote_manifest_path)
      end
    end

    def upload_to_s3(local, remote)
      execute("aws s3 cp #{local} #{remote}")
    end

    def upload_to_server(local, remote)
      execute("scp -i #{identity_file} #{local} #{ssh_user}@#{resource_host}:#{remote}")
    end

    def generate_manifest
      checksum = `openssl sha256 #{builded_src_path} | awk -F"=" '{ print $2 }'`.strip
      manifest = ERB.new(File.read(manifest_template_path)).result(binding)
      File.open(builded_manifest_path, "w") { |f| f.write(manifest) }
    end

    private

      def s3?(url)
        url.to_s.start_with?("s3://")
      end

      def builder
        @builder || Builder.new(config)
      end
  end
end
