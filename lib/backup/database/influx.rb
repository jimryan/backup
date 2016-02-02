# encoding: utf-8

module Backup
  module Database
    class Influx < Base
      class Error < Backup::Error; end

      ##
      # Path to sqlite utility (optional)
      attr_accessor :influxd_utility

      ##
      # Creates a new instance of the Influx adapter object
      def initialize(model, database_id = nil, &block)
        super
        instance_eval(&block) if block_given?

        @influxd_utility ||= utility(:influxd)
      end

      ##
      # Performs the dump using influxd
      #
      # This will be stored in the final backup package as
      #   <trigger>/databases/Influx[-<database_id>][.gz]
      def perform!
        super

        dump_file = File.join(dump_path, dump_filename)

        run("#{ influxd_utility } backup '#{ dump_file }'")

        if model.compressor
          model.compressor.compress_with do |command, ext|
            run("#{ command } -c '#{ dump_file }' > '#{ dump_file + ext }'")

            FileUtils.rm_f(dump_file)
          end
        end

        log!(:finished)
      end
    end
  end
end
