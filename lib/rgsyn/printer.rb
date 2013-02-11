# encoding: UTF-8
class Rgsyn

  module Printer
  
    def self.library_info(library)
      #puts
      puts "\033[1m#{library['name_version']}\033[0m (id: #{library['id']})"
      puts "Owner: #{library['owner']} "
      puts "Initial submit on: #{library['created_on']}"
      puts
      puts "Packages:"
      library['packages'].each do |package|
        puts "  #{package['generated'] == 'true' ? "\033[1m" : ""}" \
               "#{package['name']}\033[0m (id: #{package['id']})"
      end.join
      puts
      puts "Log:"
      puts(library['log'].gsub(/^/, '  ').gsub(%r{<[A-z/]+>}) do |tag|
             case tag
             when '<g>' then "\033[32m"
             when '<r>' then "\033[31m"
             when '<b>' then "\033[34m"
             when '<y>' then "\033[33m"
             when '</g>', '</r>', '</b>', '</y>' then "\033[0m"
             else tag
             end
           end)
      #puts
    end
    
    def self.library_list(libraries)
      libraries.sort_by{|x| x['name_version']}.each do |library|
        puts "#{library['name_version']} (id: #{library['id']})"
      end
    end
    
    def self.user_list(users)
      users.sort_by{|x| x['username']}.each do |user|
        puts "#{user['username']} (id: #{user['id']}; #{user['rights']})"
      end
    end
    
    def self.list_choices(logs)
      puts logs.sort.map { |l| "- #{l}" }.join("\n")
    end
    
  end
  
end
