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

      def log(level, message)
        logger&.send(level, message)
      end

      def execute(cmd, options = {})
        build_server.execute(cmd, options).first
      end

      def build_server
        @build_server ||= Server.new(build_host, user: build_user, options: build_ssh_options, logger: logger)
      end
  end
end
