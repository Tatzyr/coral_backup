require "pathname"
require "thor"

module CoralBackup
  class Rsync
    OSX_VOLUME_ROOT_EXCLUDED_FILES = %w[
      .DocumentRevisions-V100
      .fseventsd
      .Spotlight-V100
      .TemporaryItems
      .Trashes
      .VolumeIcon.icns
    ]

    def initialize(source, destination, excluded_files)
      unless Rsync.version.split(".").first.to_i >= 3
        raise "rsync version must be larger than 3.X.X"
      end

      @source = source
      @destination = destination
      @excluded_files = excluded_files
      @args = ["rsync", "-rlptgoxSX", "--delete", "--progress", "--stats"]
    end


    def run(action_name, dry_run: false)
      @args << "--dry-run" if dry_run

      new_destination = File.expand_path("#{action_name} backup #{Time.now.strftime("%F-%H%M%S")}", @destination)
      last_destination = find_last_destination(action_name)

      if last_destination
        @args << "--link-dest"
        @args << Pathname.new(File.expand_path(last_destination, @destination)).relative_path_from(Pathname.new(new_destination)).to_s
      end

      @excluded_files.each do |excluded_file|
        @args << "--exclude"
        @args << Pathname.new(excluded_file).relative_path_from(Pathname.new(@source)).to_s
      end

      add_osx_excluded_files

      @args << @source
      @args << new_destination

      system(@args.flatten.shelljoin)
    end

    def find_last_destination(action_name)
      Dir.chdir(@destination) {
        Dir["*"]
      }.select{|dirname|
        dirname.match(/#{Regexp.escape(action_name)} backup \d{4}-\d{2}-\d{2}-\d{6}/)
      }.sort.last
    end
    private :find_last_destination

    def add_osx_excluded_files
      if Rsync.osx?
        if File.expand_path("..", @source) == "/Volumes"
          OSX_VOLUME_ROOT_EXCLUDED_FILES.each do |excluded_file|
            @args << "--exclude"
            @args << excluded_file
          end
        end
      end
    end

    def self.version
      `rsync --version`.match(/^\s*rsync\s*version\s*(\d+\.\d+\.\d+)/)
      $1
    end

    def self.osx?
      RUBY_PLATFORM.match(/darwin/)
    end
  end
end
