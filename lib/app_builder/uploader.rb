module AppBuilder
  class Uploader < Base
    def upload
      builder.build
      if s3?(remote_src_path)
        upload_to_s3(builded_src_path, remote_src_path)
      else
        upload_to_server(builded_src_path, remote_src_path)
      end
    end

    def upload_to_s3(local, remote)
      execute("aws s3 cp #{local} #{remote}")
    end

    def upload_to_server(local, remote)
      execute("scp -i #{identity_file} #{local} #{ssh_user}@#{resource_host}:#{remote}")
    end

    private

      def s3?(path)
        path.to_s.start_with?("s3://")
      end

      def builder
        @builder || Builder.new(config)
      end
  end
end
