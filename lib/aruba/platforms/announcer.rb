require 'shellwords'

# Aruba
module Aruba
  # Platforms
  module Platforms
    # Announcer
    #
    # @private
    #
    # @example Activate your you own channel in cucumber
    #
    #   Before('@announce-my-channel') do
    #     aruba.announcer.activate :my_channel
    #   end
    #
    # @example Activate your you own channel in rspec > 3
    #
    #   before do
    #     current_example = context.example
    #     aruba.announcer.activate :my_channel if current_example.metadata[:announce_my_channel]
    #   end
    #
    #   Aruba.announcer.announce(:my_channel, 'my message')
    #
    class Announcer
      # Dev null
      class NullAnnouncer
        def announce(*)
          nil
        end

        def mode?(*)
          true
        end
      end

      # Announcer using Kernel.puts
      class KernelPutsAnnouncer
        def announce(message)
          Kernel.puts message
        end

        def mode?(m)
          :kernel_puts == m
        end
      end

      # Announcer using Main#puts
      class PutsAnnouncer
        def announce(message)
          Kernel.puts message
        end

        def mode?(m)
          :puts == m
        end
      end

      private

      attr_reader :announcers, :default_announcer, :announcer, :channels, :output_formats

      public

      def initialize(*args)
        @announcers = []
        @announcers << PutsAnnouncer.new
        @announcers << KernelPutsAnnouncer.new
        @announcers << NullAnnouncer.new

        @default_announcer = @announcers.last
        @announcer         = @announcers.first
        @channels          = {}
        @output_formats    = {}

        @options           = args[1] || {}

        after_init
      end

      private

      # rubocop:disable Metrics/MethodLength
      def after_init
        output_format :changed_configuration, proc { |n, v| format('# %s = %s', n, v) }
        output_format :changed_environment, proc { |n, v| format('$ export %s=%s', n, Shellwords.escape(v)) }
        output_format :command, '$ %s'
        output_format :directory, '$ cd %s'
        output_format :environment, proc { |n, v| format('$ export %s=%s', n, Shellwords.escape(v)) }
        output_format :full_environment, proc { |h| Aruba.platform.simple_table(h) }
        output_format :modified_environment, proc { |n, v| format('$ export %s=%s', n, Shellwords.escape(v)) }
        output_format :stderr, "<<-STDERR\n%s\nSTDERR"
        output_format :stdout, "<<-STDOUT\n%s\nSTDOUT"
        output_format :stop_signal, proc { |p, s| format('Command will be stopped with `kill -%s %s`', s, p) }
        output_format :timeout, '# %s-timeout: %s seconds'
        output_format :wait_time, '# %s: %s seconds'

        # rubocop:disable Metrics/LineLength
        if @options[:stdout]
          warn('The use of "@announce_stdout-instance" variable and "options[:stdout] = true" for Announcer.new is deprecated. Please use "announcer.activate(:stdout)" instead.')
          activate :stdout
        end
        if @options[:stderr]
          warn('The use of "@announce_stderr-instance" variable and "options[:stderr] = true" for Announcer.new is deprecated. Please use "announcer.activate(:stderr)" instead.')
          activate :stderr
        end
        if @options[:dir]
          warn('The use of "@announce_dir-instance" variable and "options[:dir] = true" for Announcer.new is deprecated. Please use "announcer.activate(:directory)" instead.')
          activate :directory
        end
        if @options[:cmd]
          warn('The use of "@announce_cmd-instance" variable and "options[:cmd] = true" for Announcer.new is deprecated. Please use "announcer.activate(:command)" instead.')
          activate :command
        end
        if @options[:env]
          warn('The use of "@announce_env-instance" variable and "options[:env] = true" for Announcer.new is deprecated. Please use "announcer.activate(:modified_environment)" instead.')
          activate :modified_enviroment
        end
        # rubocop:enable Metrics/LineLength
      end
      # rubocop:enable Metrics/MethodLength

      def output_format(channel, string = '%s', &block)
        if block_given?
          output_formats[channel.to_sym] = block
        elsif  string.is_a?(Proc)
          output_formats[channel.to_sym] = string
        else
          output_formats[channel.to_sym] = proc { |*args| format(string, *args) }
        end
      end

      public

      # Reset announcer
      def reset
        @default_announcer = @announcers.last
        @announcer         = @announcers.first
      end

      # Change mode of announcer
      #
      # @param [Symbol] m
      #   The mode to set
      def mode=(m)
        @announcer = @announcers.find { |a| f.mode? m.to_sym }

        self
      end

      # Check if channel is activated
      #
      # @param [Symbol] channel
      #   The name of the channel to check
      def activated?(channel)
        channels[channel.to_sym] == true
      end

      # Activate a channel
      #
      # @param [Symbol] channel
      #   The name of the channel to activate
      def activate(channel)
        channels[channel.to_sym] = true

        self
      end

      # Announce information to channel
      #
      # @param [Symbol] channel
      #   The name of the channel to check
      #
      # @param [Array] args
      #   Arguments
      def announce(channel, *args)
        channel = channel.to_sym

        the_output_format = if output_formats.key? channel
                              output_formats[channel]
                            else
                              proc { |v| format('%s', v) }
                            end

        message = the_output_format.call(*args)

        announcer.announce(message) if channels[channel]

        default_announcer.announce message
      end

      # @deprecated
      def stdout(content)
        warn('The announcer now has a new api to activate channels. Please use this one: announce(:stdout, message)')
        announce :stdout, content
      end

      # @deprecated
      def stderr(content)
        warn('The announcer now has a new api to activate channels. Please use this one: announce(:stderr, message)')
        announce :stderr, content
      end

      # @deprecated
      def dir(dir)
        warn('The announcer now has a new api to activate channels. Please use this one announce(:directory, message)')
        announce :directory, dir
      end

      # @deprecated
      def cmd(cmd)
        warn('The announcer now has a new api to activate channels. Please use this one announce(:command, message)')
        announce :command, cmd
      end

      # @deprecated
      def env(name, value)
        warn('The announcer now has a new api to activate channels. Please use this one: announce(:changed_environment, key, value)')

        announce :changed_environment, name, value
      end
    end
  end
end
