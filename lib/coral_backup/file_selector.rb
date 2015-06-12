require "shellwords"
require "readline"

module CoralBackup
  class FileSelector
    attr_reader :files

    def initialize
      @files = []
    end

    def add_file(filename)
      if FileTest.exist?(filename)
        @files << filename
      else
        raise Errno::ENOENT, filename
      end
    end

    def self.select
      file_selector = new
      Readline.completion_proc = Readline::FILENAME_COMPLETION_PROC
      while buf = Readline.readline("> ")
        expanded = Shellwords.split(buf)
        warn "WARNING: #{expanded.length} files are being added:" unless expanded.length == 1

        expanded.each do |ex|
          begin
            file_selector.add_file(ex)
          rescue Errno::ENOENT => e
            warn e
          else
            warn ex
          end
        end
      end

      file_selector.files.uniq
    end


    def self.single_select
      file_selector = new
      Readline.completion_proc = Readline::FILENAME_COMPLETION_PROC
      file_added = false
      while !file_added && buf = Readline.readline("> ")
        expanded = Shellwords.split(buf)
        warn "WARNING: #{expanded.length} files are being added:" unless expanded.length == 1
        begin
          file_selector.add_file(expanded[0])
        rescue Errno::ENOENT => e
          warn e
        else
          file_added = true
        end
      end

      unless file_selector.files.length == 1
        warn "ERROR: Wrong number of directories (#{file_selector.files.length} for 1):"
        file_selector.files.each do |e|
          warn e
        end
        exit 1
      end
      file_selector.files[0]
    end
  end
end
