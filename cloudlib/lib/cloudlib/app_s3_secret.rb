require 'aws-sdk-s3'
require 'aws-sdk-sts'
require 'colorized_string'
require 'fileutils'
require 'tempfile'
require 'terminal-table'
require 'yaml'

module Cloudlib
  class AppS3Secret
    attr_reader :app, :env, :remote_file

    def initialize(app: nil, env: nil, remote_file: nil, dry_run: false)
      @app = app
      @env = env
      @remote_file = remote_file
      @dry_run = dry_run
    end

    # @param [String] destination file path, pass "-" for STDOUT
    def download(destination:)
      UploadDownloadEdit.new(
        bucket: bucket,
        prefix: app_secret_path,
        dry_run: dry_run?
      ).download(destination: destination)
    end

    # @param [String] source file path, pass "-" for STDIN
    def upload(source:)
      UploadDownloadEdit.new(
        bucket: bucket,
        prefix: app_secret_path,
        dry_run: dry_run?
      ).upload(source: source)
    end

    def edit(validate_file:)
      UploadDownloadEdit.new(
        bucket: bucket,
        prefix: app_secret_path,
        dry_run: dry_run?,
      ).edit(validate_file: validate_file)
    end

    def log
      Log.new(bucket: bucket, prefix: app_secret_path).log
    end

    def log_last(last:)
      Log.new(bucket: bucket, prefix: app_secret_path).log_last(last: last)
    end

    def diff(envs:)
      puts Diff.new(bucket: bucket).table(
        envs: envs,
        keys: envs.map { |e| app_secret_path(env: e) },
      )
    end

    def dry_run?
      !!@dry_run
    end

    private

    # @return [String,nil]
    def bucket
      account_id = begin
        Aws::STS::Client.new.get_caller_identity.account
      rescue
        nil
      end

      if account_id && !account_id.empty?
        "login-gov.app-secrets.#{account_id}-us-west-2"
      end
    end

    # @example
    #  => "int/idp/v1/application.yml"
    def app_secret_path(env: self.env, app: self.app, remote_file: self.remote_file)
      "#{env}/#{app}/v1/#{remote_file}"
    end

    class UploadDownloadEdit
      attr_reader :bucket, :prefix

      def initialize(bucket:, prefix:, dry_run: false)
        @bucket = bucket
        @prefix = prefix
        @dry_run = dry_run
      end

      def dry_run?
        !!@dry_run
      end

      def download(destination:)
        log_aws_cp_command(source: "s3://#{bucket}/#{prefix}", destination: destination)

        if !dry_run?
          if destination == '-'
            s3_client.get_object(bucket: bucket, key: prefix) do |chunk|
              STDOUT.write(chunk)
            end
          else
            s3_client.get_object(
              bucket: bucket,
              key: prefix,
              response_target: destination,
            )
          end
        end
      end

      def upload(source:)
        log_aws_cp_command(source: source, destination: "s3://#{bucket}/#{prefix}")

        # TODO: find a way to stream, the issue with passing STDIN directly is that the SDK
        # tries to seek/rewind STDIN which is not allowed
        s3_client.put_object(
          bucket: bucket,
          key: prefix,
          body: source == '-' ? STDIN.read : File.new(source),
        ) if !dry_run?
      end

      def edit(validate_file:)
        file = prefix
        ext = File.extname(file)
        base = File.basename(file, ext)
        tempfile = Tempfile.new([base, ext])
        tempfile_copy = Tempfile.new([base, 'copy', ext])

        download(destination: tempfile.path)

        FileUtils.copy(tempfile.path, tempfile_copy.path)

        # Split `editor` to support editors that require arguments, e.g. "code -w"
        system(*editor.split, tempfile.path)
        if !$?.success?
          STDERR.puts "#{basename}: Editor (#{editor}) did not exit successfully. Aborting"
          exit 1
        end

        if FileUtils.compare_file(tempfile.path, tempfile_copy.path)
          STDOUT.puts "#{basename}: No changes detected in file. Exiting"
          exit 0
        end


        STDOUT.puts "#{basename}: Here's a preview of your changes:"
        system(differ, tempfile_copy.path, tempfile.path)

        valid, error = check_file(File.read(tempfile.path))
        if !valid
          if validate_file
            STDERR.puts "#{basename}: Invalid file (to override this check use --skip-validation)"
            STDERR.puts error.inspect
            exit 1
          else
            STDERR.puts "#{basename}: warning, changes did not validate"
            STDERR.puts error.inspect
          end
        end

        STDOUT.puts "#{basename}: Upload changes to S3? (y/n)"
        fd = IO.sysopen("/dev/tty", "r")
        tty_in = IO.new(fd,"r")

        input = tty_in.read(1)
        if input == 'y'
          upload(source: tempfile.path) if !dry_run?
        else
          STDERR.puts "#{basename}: diff not approved, not uploading to S3"
        end
      ensure
        tempfile.unlink
        tempfile_copy.unlink
      end

      private

      # logs an equivalent aws command line
      def log_aws_cp_command(source:, destination:)
        s3_args = ['aws', 's3', 'cp', source, destination]
        STDERR.puts s3_args.join(' ')
      end

      def editor
        @editor ||= ENV['VISUAL'] || ENV['EDITOR'] || `which vim`.chomp
      end

      def differ
        @differ ||= begin
          cmd = `which colordiff`.chomp
          if !$?.success?
            cmd = `which diff`.chomp
          end
          cmd
        end
      end

      def s3_client
        @s3_client ||= Aws::S3::Client.new
      end

      # @return [true, Array(false, Error)]
      def check_file(content)
        extension = File.extname(prefix)
        case extension.downcase
        when '.yml', '.yaml'
          require 'yaml'
          YAML.parse(content)
          true
        when '.json'
          require 'json'
          JSON.parse(content)
          true
        else
          true
        end
      rescue => err
        [false, err]
      end
    end

    class Log
      attr_reader :bucket, :prefix

      def initialize(bucket:, prefix:)
        @bucket = bucket
        @prefix = prefix
      end

      def log
        # TODO: add some sort of pager behavior like "git log"
        versions.each_cons(2) do |newer, older|
          output_diff(older: older, newer: newer)
        end
      rescue Interrupt
        # ctrl-c is ok!
        nil
      end

      def log_last(last:)
        if last > 1
          count = 0
          versions.each_cons(2) do |newer, older|
            has_diff = output_diff(
              older: older,
              newer: newer,
              print_only_if_diff: true
            )
            count += 1 if has_diff
            return if count >= last
          end
        else
          # show the current diff
          current, older, *rest = versions
          output_diff(older: older, newer: current)
        end
      rescue Interrupt
        # ctrl-c is ok!
        nil
      end

      private

      # @param [Aws::S3::Types::ObjectVersion] older
      # @param [Aws::S3::Types::ObjectVersion] newer
      # @return [Boolean] true if the versions differ
      def output_diff(older:, newer:, out: STDOUT, print_only_if_diff: false)
        Tempfile.create do |newer_file|
          Tempfile.create do |older_file|
            s3_client.get_object(
              bucket: bucket,
              key: prefix,
              version_id: newer.version_id,
              response_target: newer_file,
            )

            s3_client.get_object(
              bucket: bucket,
              key: prefix,
              version_id: older.version_id,
              response_target: older_file,
            )

            no_diff = system('cmp', '-s', older_file.path, newer_file.path)

            if print_only_if_diff && no_diff
              return false
            end

            out.puts "Comparing: #{newer.last_modified} (#{newer.version_id})"
            out.puts "       to: #{older.last_modified} (#{older.version_id})"

            success = system(differ, older_file.path, newer_file.path, out: out)

            out.puts "(no diff)" if no_diff

            !no_diff
          end
        end
      end

      def differ
        @differ ||= begin
          cmd = `which colordiff`.chomp
          if !$?.success?
            cmd = `which diff`.chomp
          end
          cmd
        end
      end

      def versions
        @versions ||= s3_client.list_object_versions(
          bucket: bucket,
          prefix: prefix
        ).versions
      end

      def s3_client
        @s3_client ||= Aws::S3::Client.new
      end
    end

    class Diff
      attr_reader :bucket

      def initialize(bucket:)
        @bucket = bucket
      end

      # @return [String]
      def table(envs:, keys:)
        contents = envs.zip(keys).map do |env, key|
          YAML.load(
            s3_client.get_object(bucket: bucket, key: key).body.read
          )['production']
        end

        all_keys = contents.flat_map(&:keys).uniq.sort
        rows = []
        rows << ['key', *envs]
        rows << :separator

        all_keys.each do |key|
          values = contents.map do |content|
            color_code(
              first_value: contents.first[key],
              current_value: content[key],
              display_value: redact(content[key]),
            )
          end

          rows << [key, *values]
        end

        Terminal::Table.new(rows: rows, style: { padding_left: 0 })
      end

      private

      def color_code(first_value:, current_value:, display_value:)

        color, change_indicator = if first_value && current_value.nil?
          [:red, '-']
        elsif first_value.nil? && current_value
          [:green, '+']
        elsif first_value != current_value
          [:yellow, '!']
        else
          [:default, ' ']
        end

        [
          ColorizedString[change_indicator].colorize(:light_black),
          ColorizedString[display_value].colorize(color)
        ].join
      end

      def redact(value)
        case value
        when true, false, 'true', 'false', Numeric, /\A\d+(\.\d+)?\Z/
          value.to_s
        when String
          if value.length > 6
            num_dots = [(value.length - 6), 3].min
            "#{value[0..2]}#{'.' * num_dots}#{value[-3..-1]}"
          else
            value # TODO: is there anything actually secret shorter than 6 chars?
          end
        when nil
          '(null)'
        else
          "UNKNOWN VALUE #{value.class}"
        end
      end

      def s3_client
        @s3_client ||= Aws::S3::Client.new
      end
    end
  end
end
