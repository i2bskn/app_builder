module AppBuilder
  class Server
    attr_accessor :address, :user, :options, :logger

    LOCAL_ADDRESSES = %w(local localhost 127.0.0.1).freeze

    def initialize(address = nil, user: nil, options: {}, logger: nil)
      @address = address
      @user    = user || ENV.fetch("USER", nil)
      @options = options
      @logger  = logger
    end

    def execute(*cmds)
      results = []

      options = cmds.last.is_a?(Hash) ? cmds.pop : {}
      if local?
        cmds.each do |cmd|
          message = "Execute command [local]: #{cmd}"
          message += " (with: #{options.inspect})" unless options.empty?
          log(:info, message)

          stdout, stderr, status = Open3.capture3(cmd, **options)
          log(:error, "Failed [#{status.exitstatus}]: #{stderr}") unless status.success?
          results << stdout
        end
      else
        ssh_start do |ssh|
          cmds.each do |cmd|
            cmd = "cd #{options[:chdir]}; #{cmd}" if options.has_key?(:chdir)
            log(:info, "Execute command [#{address}]: #{cmd}")
            results << ssh.exec!(cmd).chomp
          end
        end
      end

      results
    end

    def upload(src_path, dest_path)
      erb = File.extname(src_path) == ".erb".freeze
      if local?
        if erb
          log(:info, "Create #{dest_path} from #{src_path}")
          File.open(dest_path, "w") { |f| f.write(ERB.new(File.read(src_path), nil, "-").result) }
        else
          execute("cp #{src_path} #{dest_path}")
        end
      else
        ssh_start do |ssh|
          log(:info, "Upload: local:#{src_path} to #{address}:#{dest_path}")
          if erb
            begin
              f = Tempfile.open(File.basename(dest_path))
              f.write(ERB.new(File.read(src_path), nil, "-").result)
              f.close
              ssh.scp.upload!(f.path, dest_path)
            rescue
              f.unlink
            end
          else
            ssh.scp.upload!(src_path, dest_path)
          end
        end
      end
    end

    def ssh_start
      raise ArgumentError unless block_given?
      Net::SSH.start(address, ssh_user, ssh_options) { |ssh| yield ssh }
    end

    def local?
      address.nil? || LOCAL_ADDRESSES.include?(address.to_s)
    end

    private

      def log(level, message)
        logger&.send(level, message)
      end

      def ssh_options
        return default_ssh_options if options.nil? || options.empty?
        default_ssh_options.merge(options)
      end

      def ssh_user
        user || ENV["USER"]
      end

      def default_ssh_options
        { port: 22, keys: File.expand_path("~/.ssh/id_rsa"), forward_agent: true }
      end
  end
end
