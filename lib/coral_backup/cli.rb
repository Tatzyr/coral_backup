require "pathname"
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
      source = FileSelector.select_file
      unless FileTest.directory?(source)
        warn "ERROR: Not a directory: #{source}"
        exit 1
      end
      source << "/" unless source.end_with?("/")

      puts "Drag and drop or input exclusion files/directories."
      puts "Press Ctrl + D to finish."
      exclusions = FileSelector.select_files
      exclusions.map! {|filename|
        if FileTest.directory?(filename)
          filename << "/" unless filename.end_with?("/")
        end
        filename
      }
      exclusions.uniq!

      puts "Drag and drop or input destination directory."
      destination = FileSelector.select_file
      unless FileTest.directory?(destination)
        warn "ERROR: Not a directory: #{destination}"
        exit 1
      end
      destination << "/" unless destination.end_with?("/")

      @settings.add(action_name, source, destination, exclusions)
    rescue RuntimeError => e
      warn "ERROR: #{e}"
      exit 1
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

    desc "exec <ACTION>", "Execute the backup action"
    option :"dry-run", type: :boolean, aliases: :d, desc: "Show what would have been backed up, but do not back them up"
    option :"updating-time", type: :boolean, default: true, aliases: :t, desc: "Update time when backup is finished"
    def exec(action_name)
      data = @settings.action_data(action_name)
      source = data[:source]
      destination = data[:destination]
      exclusions = data[:exclusions]
      dry_run = options[:"dry-run"]

      rsync = Rsync.new(source, destination, exclusions)
      rsync.run(action_name, dry_run: dry_run)

      updating_time = options[:"updating-time"]
      @settings.update_time(action_name, Time.now) if !dry_run && updating_time
    rescue RuntimeError => e
      warn "ERROR: #{e}"
      exit 1
    end


    desc "info <ACTION>", "Show information about the backup action"
    def info(action_name)
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

      print "Last backup executed at: "
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
  end
end
