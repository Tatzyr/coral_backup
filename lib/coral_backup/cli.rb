require "thor"

module CoralBackup
  class CLI < Thor
    def initialize(*args)
      super
      @settings = Settings.new
    end

    desc "add <ACTION>", "Add a new backup action"
    def add(action_name)
      if @settings.exist_action?(action_name)
        warn "ERROR: Backup action `#{action_name}' already exists."
        exit 1
      end

      puts "Drag and drop or input source directory."
      source = FileSelector.single_select
      unless FileTest.directory?(source)
        warn "ERROR: Not a directory: #{source}"
        exit 1
      end
      source << "/" unless source.end_with?("/")

      puts "Drag and drop or input exclusion files/directories."
      puts "Press Ctrl + D to finish."
      exclusions = FileSelector.select
      exclusions.map! {|filename|
        if FileTest.directory?(filename)
          filename << "/" unless filename.end_with?("/")
        end
        filename
      }
      exclusions.uniq!

      puts "Drag and drop or input destination directory."
      destination = FileSelector.single_select
      unless FileTest.directory?(destination)
        warn "ERROR: Not a directory: #{destination}"
        exit 1
      end
      destination << "/" unless destination.end_with?("/")

      @settings.add(action_name, source, destination, exclusions)
    end

    desc "delete <ACTION>", "Delete the backup action"
    def delete(action_name)
      @settings.delete(action_name)
    rescue ArgumentError => e
      warn "ERROR: #{e}"
      exit 1
    end

    desc "list", "Show all backup actions"
    def list
      puts @settings.action_names
    end

    map run: :__run
    desc "run <ACTION>", "Run the backup action"
    option :"dry-run", :type => :boolean, aliases: :d, desc: "Show what would have been backed up, but do not back them up"
    def __run(action_name)
      unless rsync_version.split(".").first.to_i >= 3
        warn "ERROR: rsync version must be larger than 3.X.X"
        exit 1
      end

      time = Time.now
      data = @settings.action_data(action_name)

      destination = data[:destination]
      dryrun = options[:"dry-run"]
      exclusions = data[:exclusions]
      source = data[:source]

      args = ["rsync", "-rlptgoxS", "--delete", "-X", "--progress", "--stats"]
      args << "--dry-run" if dryrun

      new_destination = File.expand_path("#{action_name} backup #{Time.now.strftime("%F-%H%M%S")}", destination)
      old_destination =
        Dir.chdir(destination) {
          Dir["*"]
        }.select{|dirname|
          dirname.match(/#{Regexp.escape(action_name)} backup \d{4}-\d{2}-\d{2}-\d{6}/)
        }.sort.last

      if old_destination
        args << "--link-dest"
        args << Pathname.new(File.expand_path(old_destination, destination)).relative_path_from(Pathname.new(new_destination)).to_s
      end

      exclusions.each do |exclusion|
        args << "--exclude"
        args << Pathname.new(exclusion).relative_path_from(Pathname.new(source)).to_s
      end

      args << source
      args << new_destination

      system(args.flatten.shelljoin)

      @settings.update_time(action_name, time) unless dryrun
    end


    desc "show <ACTION>", "Show information about the backup action"
    def show(action_name)
      data = @settings.action_data(action_name)

      puts "Source: #{data[:source]}"
      puts "Destination: #{data[:destination]}"
      print "exclusions: "
      if data[:exclusions].empty?
        puts "(No exclusions)"
      else
        puts "#{data[:exclusions].size} exclusion(s)"
        puts data[:exclusions]
      end

      print "Last backup run at: "
      if data[:last_run_time].nil?
        puts "No backup yet"
      else
        puts data[:last_run_time]
      end
    rescue  ArgumentError => e
      warn "ERROR: #{e}"
      exit 1
    end

    desc "version", "Print the version"
    def version
      puts VERSION
    end

    no_tasks do
      def rsync_version
        `rsync --version`.match(/^\s*rsync\s*version\s*(\d+\.\d+\.\d+)/)
        $1
      end
    end
  end
end
