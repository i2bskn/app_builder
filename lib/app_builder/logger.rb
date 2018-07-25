module AppBuilder
  class Logger < ::Logger
    class Formatter < ::Logger::Formatter
      Format = "%s\t%s\t%d\t%s\n".freeze

      def call(severity, time, progname, msg)
        Format % [severity, format_datetime(time), $$, msg2str(msg)]
      end

      private

        def format_datetime(time)
          time.strftime(@datetime_format || "%F %H:%M:%S.%6N".freeze)
        end
    end

    def initialize(logdev, shift_age = 0, shift_size = 1048576)
      super
      @default_formatter = Formatter.new
    end

    def format_message(severity, datetime, progname, msg)
      apply_severity_color(
        severity,
        (@formatter || @default_formatter).call(severity, datetime, progname, msg),
      )
    end

    private

      def apply_severity_color(severity, msg)
        case severity
        when "DEBUG".freeze
          "\033[2m#{msg}\033[m"
        when "INFO".freeze
          "\033[32m#{msg}\033[m"
        when "WARN".freeze
          "\033[33m#{msg}\033[m"
        when "ERROR".freeze, "FATAL".freeze
          "\033[31m#{msg}\033[m"
        else
          msg
        end
      end
  end
end
