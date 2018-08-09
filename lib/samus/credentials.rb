module Samus
  class Credentials
    attr_reader :name

    class << self
      attr_accessor :credentials
    end

    @credentials = {}

    def initialize(name)
      @name = name
      load_credential_file
    end

    def load
      return self.class.credentials[name] if self.class.credentials[name]

      hsh = {}
      data = nil
      if File.executable?(@file)
        data = `#{@file}`
        if $?.to_i != 0
          Samus.error "Loading credential #{name} failed with #{$?}"
        end
      else
        data = File.read(@file)
      end

      data.split(/\r?\n/).each do |line|
        name, value = *line.strip.split(':')
        if value.nil?
          Samus.error "Failed to parse credential from #{@file} (exec bit: #{File.executable?(@file)})"
        end

        hsh["_creds_#{name.strip.downcase}"] = value.strip
      end

      self.class.credentials[name] = hsh
    end

    private

    def load_credential_file
      Samus.config_paths.each do |path|
        file = File.join(path, 'credentials', name)
        if File.exist?(file)
          @file = file
          return
        end
      end
      Samus.error "Could not find credential: #{name} " \
                  "(SAMUS_CONFIG_PATH=#{Samus.config_paths.join(':')})"
    end
  end
end
