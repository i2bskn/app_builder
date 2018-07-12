module AppBuilder
  class Base
    extend Forwardable

    attr_accessor :config
    Config::PARAMETERS.each do |name|
      def_delegator :config, name
    end

    def initialize(conf = nil)
      @config = conf || Config.new
    end

    private

      def create_base_directories
        execute("mkdir -p #{working_path} #{archive_path} #{build_path}")
      end

      def update_repository
        if File.exist?("#{repo_path}/HEAD")
          execute("git remote update", chdir: repo_path)
        else
          execute("git clone --mirror #{remote_repository} #{repo_path}")
        end
      end

      def create_revision_to(path)
        rev_hash = { "branch" => branch, "revision" => revision }
        File.open(path, "w") { |f| f.write(rev_hash.to_yaml) }
        log(:info, "Create revision: #{rev_hash.inspect}")
      end

      def log(level, message)
        logger&.send(level, message)
      end

      def execute(cmd, options = {})
        build_server.execute(cmd, options).first
      end

      def build_server
        @build_server ||= Server.new(:localhost, logger: logger)
      end
  end
end
