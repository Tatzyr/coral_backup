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

      puts "Drag and drop or input excluded files/directories."
      puts "Press Ctrl + D to finish."
      excluded_files = FileSelector.select_files
      excluded_files.map! {|filename|
        if FileTest.directory?(filename)
          filename << "/" unless filename.end_with?("/")
        end
        filename
      }
      excluded_files.uniq!

      puts "Drag and drop or input destination directory."
      destination = FileSelector.select_file
      unless FileTest.directory?(destination)
        warn "ERROR: Not a directory: #{destination}"
        exit 1
      end
      destination << "/" unless destination.end_with?("/")

      @settings.add(action_name, source, destination, excluded_files)
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
      excluded_files = data[:excluded_files]
      dry_run = options[:"dry-run"]

      rsync = Rsync.new(source, destination, excluded_files)
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
      print "Excluded files: "
      if data[:excluded_files].empty?
        puts "(No excluded files)"
      else
        puts "#{data[:excluded_files].size} excluded file(s)"
        puts data[:excluded_files]
      end

      print "Last backup executed at: "
      if data[:last_excuted_at]
        puts data[:last_excuted_at]
      else
        puts "No backup yet"
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
