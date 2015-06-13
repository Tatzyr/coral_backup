require "yaml"

module CoralBackup
  class Settings
    INITIAL_SETTINGS = {
      actions: {}
    }

    def initialize(filename = "#{Dir.home}/.coral_backup")
      @filename = filename
      @settings = file_load
    end

    def action_data(action_name)
      raise ArgumentError, "Backup action `#{action_name}' does not exist." unless exist_action?(action_name)
      @settings[:actions][action_name]
    end

    def action_names
      @settings[:actions].keys
    end

    def exist_action?(action_name)
      action_names.include?(action_name)
    end

    def add(action_name, source, destination, exclusions)
      raise ArgumentError, "Backup action `#{action_name}' already exists." if exist_action?(action_name)
      @settings[:actions][action_name] = { source: source, destination: destination, exclusions: exclusions }
      file_dump
    end

    def delete(action_name)
      raise ArgumentError, "Backup action `#{action_name}' does not exist." unless exist_action?(action_name)
      @settings[:actions].delete(action_name)
      file_dump
    end

    def update_time(action_name, time)
      raise ArgumentError, "Backup action `#{action_name}' does not exist." unless exist_action?(action_name)
      @settings[:actions][action_name][:last_run_time] = time.to_s
      file_dump
    end

    private
    def file_load
      return INITIAL_SETTINGS unless FileTest.exist?(@filename)

      YAML.load_file(@filename)
    end

    def file_dump
      open(@filename, "w") do |f|
        YAML.dump(@settings, f)
      end
    end
  end
end
