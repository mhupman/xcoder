module Xcode
  class ProvisioningProfile
    attr_reader :path, :name, :uuid, :identifiers, :devices, :appstore
    def initialize(path)
      
      raise "Provisioning profile '#{path}' does not exist" unless File.exists? path
      
      @path = path
      @identifiers = []
      @devices = []
      @appstore = true
      
      # TODO: im sure this could be done in a nicer way.  maybe read out the XML-like stuff and use the plist -> json converter
      uuid = nil
      File.open(path, "rb") do |f|
        input = f.read
        
        if input=~/ProvisionedDevices/
          @appstore = false
        end
        
        if input=~/<key>ProvisionedDevices<\/key>.*?<array>(.*?)<\/array>/im
          $1.split(/<string>/).each do |id|
            next if id.nil? or id.strip==""
            @devices << id.gsub(/<\/string>/,'').strip
          end
        end
        
        input=~/<key>UUID<\/key>.*?<string>(.*?)<\/string>/im
        @uuid = $1.strip
                
        input=~/<key>Name<\/key>.*?<string>(.*?)<\/string>/im
        @name = $1.strip
        
        input=~/<key>ApplicationIdentifierPrefix<\/key>.*?<array>(.*?)<\/array>/im
        $1.split(/<string>/).each do |id|
          next if id.nil? or id.strip==""
          @identifiers << id.gsub(/<\/string>/,'').strip
        end
      end
    
    end
    
    def appstore?
      @appstore
    end

    def self.profiles_path
      File.expand_path "~/Library/MobileDevice/Provisioning\\ Profiles/"  
    end
    
    def install_path
      "#{ProvisioningProfile.profiles_path}/#{self.uuid}.mobileprovision"
    end
    
    def install
      Xcode::Shell.execute("cp #{self.path} #{self.install_path}")   
    end
    
    def uninstall
      Xcode::Shell.execute("rm -f #{self.install_path}")
    end

    def self.installed_profiles
      Dir["#{self.profiles_path}/*.mobileprovision"].map do |file|
        ProvisioningProfile.new(file)
      end
    end
    
  end
end