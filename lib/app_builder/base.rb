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
        @build_server ||= Server.new(:localhost, logger: logger)
      end
  end
end
