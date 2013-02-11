require 'rest_client'
require 'json'
require 'yaml'

class Rgsyn

  VERSION = '0.1.0'
  YUM_REPOS_D = '/etc/yum.repos.d'
  
  class HostNotSpecifiedError < RuntimeError; end
  class BadResponseError < RuntimeError; end
  class PermissionDeniedError < RuntimeError; end

  def initialize(conf_file)
    @conf_file = conf_file
    if File.exists?(conf_file)
      config = YAML::load_file(conf_file)
      @host = config["host"]
      @username = config["username"]
      @yum_files = config["yum_files"] || []
    else
      @yum_files = []
    end
  end
  
  def save
    File.open(@conf_file, 'w') do |file|
      file.write({"host" => @host, "username" => @username,
        "yum_files" => @yum_files}.to_yaml)
    end
  end
  
  private :save
  
  def host_valid?
    begin
      response = talk(:get, "info")
      response.kind_of?(Hash) && response['name'] == 'rgsyn'
    rescue BadResponseError, JSON::ParserError
      false
    end
  end
  
  def host=(value)
    @host = value && value.chomp('/')
    save
  end
  
  def host
    @host
  end
  
  def username=(value)
    @username = value
    save
  end
  
  def username
    @username
  end
  
  def talk(method, path, params = {}, credentials = nil)
    HostNotSpecifiedError if @host.nil?
    begin
      response = 
        if credentials
          RestClient::Request.new(:method => method,
            :url => "#{@host}/#{path}", :user => credentials[:username],
            :password => credentials[:password], :payload => params).execute
        else
          RestClient::Request.new(:method => method,
            :url => "#{@host}/#{path}", :payload => params).execute
        end
    rescue RestClient::Unauthorized => ex
      raise(BadResponseError, ex.to_s)
    rescue RestClient::Exception => ex
      if ex.http_code == 300
        response = ex.response
      else
        raise(BadResponseError, ex.to_s +
          ((ex.response == "") ? "" : ": #{ex.response.to_s}"))
      end
    end
      
    content_type = response.headers[:content_type].split(';').map { |x|
      x.strip }
    if content_type.include?('application/json')
      return JSON.parse(response)
    else
      return response
    end
  end
  
  # Set up Yum by creating .repo file in /etc/yum.repos.d directory.
  #
  def yum_setup(op_sys)
    url = "#{@host}/rpm_repo/#{op_sys}/"
    url_strip = @host.gsub(%r{\Ahttp\://}, '').gsub('/', '-')
    name = "rgsyn-#{url_strip}-#{op_sys}"
    file = File.join(YUM_REPOS_D, "#{name}.repo")
    
    begin
      if File.exists?(file)
        return false
      else
        File.open(file, 'w') do |f|
          f.write <<-END
[#{name}]
name=#{name}
baseurl=#{url}
enabled=1
END
        end
        @yum_files << file
        save
        return true
      end
    rescue Errno::EACCES
      raise PermissionDeniedError
    end
  end
  
  # Returns false if no files were removed, true otherwise.
  #
  def yum_undo
    @yum_files.each do |file|
      raise PermissionDeniedError unless File.writable?(file) &&
        File.writable?(File.dirname(file))
    end
    @yum_files.each { |file| FileUtils.rm(file) }
    res = ! @yum_files.empty?
    @yum_files.clear
    save
    res
  end
  
end
