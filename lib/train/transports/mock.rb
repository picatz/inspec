# encoding: utf-8
#
# author: Dominik Richter
# author: Christoph Hartmann

require 'train/plugins'
require 'digest'

module Train::Transports
  class Mock < Train.plugin(1)
    name 'mock'

    attr_accessor :files, :commands, :os

    def initialize(conf = nil)
      @conf = conf || {}
      @files = {}
      @os = {}
      @commands = {}
      trace_calls if @conf[:verbose]
    end

    def mock_os(value)
      @os = OS.new(self, value)
    end

    def run_command(cmd)
      @commands[cmd] ||
        MockCommand.new(cmd, nil, nil, 0)
    end

    def file(path)
      @files[path] ||= File.new(self, path)
    end

    def to_s
      'Mock Backend'
    end

    private

    def trace_calls
      interface_methods = {
        'Train::Transports::Mock' => Train::Transports::Mock.instance_methods(false),
        'Train::Transports::Mock::File' => FileCommon.instance_methods(false),
        'Train::Transports::Mock::OS' => OSCommon.instance_methods(false),
      }

      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Lint/Eval
      set_trace_func proc { |event, _file, _line, id, binding, classname|
        unless classname.to_s.start_with?('Train::Transports::Mock') and
               event == 'call' and
               interface_methods[classname.to_s].include?(id)
          next
        end
        # kindly borrowed from the wonderful simple-tracer by matugm
        arg_names = eval(
          'method(__method__).parameters.map { |arg| arg[1].to_s }',
          binding)
        args = eval("#{arg_names}.map { |arg| eval(arg) }", binding).join(', ')
        prefix = '-' * (classname.to_s.count(':') - 2) + '> '
        puts("#{prefix}#{id} #{args}")
      }
      # rubocop:enable all
    end
  end
end

class Train::Transports::Mock
  Command = Struct.new(:stdout, :stderr, :exit_status)
end

class Train::Transports::Mock
  class OS < OSCommon
    def initialize(backend, desc)
      super(backend, desc)
    end

    def detect_family
      # no op, we do not need to detect the os
    end
  end
end

class Train::Transports::Mock
  class File < FileCommon
    %w{
      exist? mode owner group link_target link_path content mtime size
      selinux_label product_version file_version path
      type
    }.each do |m|
      attr_accessor m.tr('?', '').to_sym
    end

    def initialize(_runtime, path)
      @path = path
      @type = :unknown
      @exist = false
    end
  end
end