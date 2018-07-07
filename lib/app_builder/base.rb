module AppBuilder
  class Base
    extend Forwardable

    attr_accessor :config
    ::AppBuilder::Config::VALID_OPTIONS.each do |name|
      def_delegator :config, name
    end

    def initialize(config = nil)
      @config = config || ::AppBuilder::Config.new
    end

    private

      def execute(cmd, options = {})
        log(:info, "Execute command [local]: #{cmd}")
        stdout, stderr, status = Open3.capture3(cmd, **options)
        log(:error, "Failed [#{status.exitstatus}]: #{stderr}") unless status.success?
        stdout.chomp
      end

      def log(level, message)
        logger&.send(level, message)
      end
  end
end
