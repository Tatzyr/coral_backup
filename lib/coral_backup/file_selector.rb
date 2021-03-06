require "shellwords"
require "readline"

module CoralBackup
  class FileSelector
    def self.select_file
      new.instance_eval do
        while @files.size < 1 && raw_input = Readline.readline
          process_input(raw_input)
        end
        raise "Wrong number of files (#{@files.length} for 1)" unless @files.length == 1
        @files.first
      end
    end

    def self.select_files
      new.instance_eval do
        while raw_input = Readline.readline
          process_input(raw_input)
        end
        @files.uniq
      end
    end

    def initialize
      @files = []
    end

    private
    def process_input(raw_input)
      filenames = Shellwords.split(raw_input)
      warn "WARNING: #{filenames.length} files are being added:" unless filenames.length == 1
      filenames.each do |ex|
        begin
          store_file(ex)
        rescue Errno::ENOENT => e
          warn e
        end
      end
    end

    def store_file(filename)
      raise Errno::ENOENT, filename unless FileTest.exist?(filename)
      filenames = File.expand_path(filename)
      @files << File.expand_path(filenames)
      warn filenames
    end
  end
end
