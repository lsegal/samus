module Samus
  class Credentials
    attr_reader :name

    @@credentials = {}

    def initialize(name)
      @name = name
      load_credential_file
    end

    def load
      return @@credentials[name] if @@credentials[name]

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
        hsh["_creds_#{name.strip.downcase}"] = value.strip
      end

      @@credentials[name] = hsh
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
      Samus.error "Could not find credential: #{name} " +
           "(SAMUS_CONFIG_PATH=#{Samus.config_paths.join(':')})"
    end
  end
end