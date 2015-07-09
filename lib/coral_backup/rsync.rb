require "pathname"
require "thor"

module CoralBackup
  class Rsync
    OSX_VOLUME_ROOT_EXCLUSIONS = %w[
      .DocumentRevisions-V100
      .fseventsd
      .Spotlight-V100
      .TemporaryItems
      .Trashes
      .VolumeIcon.icns
    ]

    def initialize(source, destination, exclusions)
      unless Rsync.version.split(".").first.to_i >= 3
        raise "rsync version must be larger than 3.X.X"
      end

      @source = source
      @destination = destination
      @exclusions = exclusions
    end


    def run(action_name, dry_run: false)
      args = ["rsync", "-rlptgoxSX", "--delete", "--progress", "--stats"]
      args << "--dry-run" if dry_run

      new_destination = File.expand_path("#{action_name} backup #{Time.now.strftime("%F-%H%M%S")}", @destination)
      old_destination =
        Dir.chdir(@destination) {
          Dir["*"]
        }.select{|dirname|
          dirname.match(/#{Regexp.escape(action_name)} backup \d{4}-\d{2}-\d{2}-\d{6}/)
        }.sort.last

      if old_destination
        args << "--link-dest"
        args << Pathname.new(File.expand_path(old_destination, @destination)).relative_path_from(Pathname.new(new_destination)).to_s
      end

      @exclusions.each do |exclusion|
        args << "--exclude"
        args << Pathname.new(exclusion).relative_path_from(Pathname.new(@source)).to_s
      end

      if Rsync.osx?
        if File.expand_path("..", @source) == "/Volumes"
          OSX_VOLUME_ROOT_EXCLUSIONS.each do |vr_exclusion|
            args << "--exclude"
            args << vr_exclusion
          end
        end
      end

      args << @source
      args << new_destination

      system(args.flatten.shelljoin)
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
