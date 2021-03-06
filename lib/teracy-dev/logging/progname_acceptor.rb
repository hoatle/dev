require_relative 'acceptor'

module TeracyDev
  module Logging
    # filter messages by LOG_PROGNAME env var
    # LOG_PROGNAME=TeracyDev => display all logs has progname matching TeracyDev,
    # eg: TeracyDev, TeracyDev::Config, etc
    #
    # LOG_PROGNAME=TeracyDev::Config => display all logs has progname matching TeracyDev::Config,
    # eg: TeracyDev::Config, TeracyDev::Config::Provisioners, etc
    #
    # LOG_PROGNAME="TeracyDev::Loader|TeracyDev::Location"
    # => display all logs having progname matching this regex
    class PrognameAcceptor < Acceptor
      def initialize
        super
        @log_progname = ENV['LOG_PROGNAME'] || '.*' # use regex to check with progname
      end

      def accept(_severity, _datetime, progname, _msg)
        return !Regexp.new(@log_progname).match(progname.to_s).nil?
      end
    end
  end
end
