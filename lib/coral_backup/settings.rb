require "toml"

module CoralBackup
  class Settings
    INITIAL_SETTINGS = {
      actions: {}
    }

    def initialize(filename = "#{Dir.home}/.coral")
      @filename = filename
      @settings = file_load
    end

    def action_data(action_name)
      raise ArgumentError, "Backup action `#{action_name}' does not exist." unless exist_action?(action_name)
      @settings[:actions][action_name.to_sym]
    end

    def action_names
      @settings[:actions].keys.map(&:to_s)
    end

    def exist_action?(action_name)
      action_names.include?(action_name)
    end

    def add(action_name, source, destination, exclusions)
      raise ArgumentError, "Backup action `#{action_name}' already exists." if exist_action?(action_name)
      @settings[:actions][action_name.to_sym] = { source: source, destination: destination, exclusions: exclusions }
      file_dump
    end

    def delete(action_name)
      raise ArgumentError, "Backup action `#{action_name}' does not exist." unless exist_action?(action_name)
      @settings[:actions].delete(action_name.to_sym)
      file_dump
    end

    def update_time(action_name, time)
      raise ArgumentError, "Backup action `#{action_name}' does not exist." unless exist_action?(action_name)
      @settings[:actions][action_name.to_sym][:last_run_time] = time.to_s
      file_dump
    end

    private
    def file_load
      return INITIAL_SETTINGS unless FileTest.exist?(@filename)

      TOML.load_file(@filename, symbolize_keys: true)
    end

    def file_dump
      open(@filename, "w") do |f|
        f.puts TOML.dump(@settings)
      end
    end
  end
end
