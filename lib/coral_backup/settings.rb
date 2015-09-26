require "yaml"

module CoralBackup
  class Settings
    INITIAL_SETTINGS = {
      actions: {}
    }

    def initialize(filename = "#{Dir.home}/.coral_backup")
      @filename = filename
      @settings = load!
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

    def add(action_name, source, destination, excluded_files)
      raise ArgumentError, "Backup action `#{action_name}' already exists." if exist_action?(action_name)
      @settings[:actions][action_name] = { source: source, destination: destination, excluded_files: excluded_files }
      save!
    end

    def delete(action_name)
      raise ArgumentError, "Backup action `#{action_name}' does not exist." unless exist_action?(action_name)
      @settings[:actions].delete(action_name)
      save!
    end

    def update_time(action_name, time)
      raise ArgumentError, "Backup action `#{action_name}' does not exist." unless exist_action?(action_name)
      @settings[:actions][action_name][:last_excuted_at] = time.to_s
      save!
    end

    private
    def load!
      return INITIAL_SETTINGS unless FileTest.exist?(@filename)
      YAML.load_file(@filename)
    end

    def save!
      open(@filename, "w") do |f|
        YAML.dump(@settings, f)
      end
    end
  end
end
