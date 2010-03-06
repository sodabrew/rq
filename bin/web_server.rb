#!/usr/bin/ruby

$:.unshift(File.join(File.dirname(__FILE__), ".."))

Dir.glob(File.join("gems", "gems", "*", "lib")).each do |lib|
  $LOAD_PATH.unshift(File.expand_path(lib))
end

Dir.chdir(File.join(File.dirname(__FILE__), ".."))

require 'rubygems'
gem_paths = [File.expand_path(File.join("gems")),  Gem.default_dir]
Gem.clear_paths
Gem.send :set_paths, gem_paths.join(":")

require 'code/router.rb'

require 'json'

require 'unixrack.rb'

router = MiniRouter.new

def load_config
  begin
    data = File.read('config/config.json')
    config = JSON.parse(data)
    $host = config['host']
    $port = config['port']
    $addr = config['addr']
  rescue
    puts "Couldn't read config/config.json file properly. Exiting"
    exit! 1
  end
end

if ARGV[0] == "install"
  $host = "127.0.0.1"
  $port = "3333"
  $addr = "0.0.0.0"
else
  load_config
end

#pid = fork do
#  Signal.trap('HUP', 'IGNORE') # Don't die upon logout
#  FileUtils.mkdir_p("log")

#  STDIN.reopen("/dev/null")
#  STDOUT.reopen("log/server.log", "a+")
#  STDOUT.sync = true
#  $stderr = STDOUT

#  Signal.trap("TERM") do 
#    Process.kill("KILL", Process.pid)
#  end

  Rack::Handler::UnixRack.run(router, {:port => $port,
                                       :host => $host,
                                       :listen => $addr})
#end

#Process.detach(pid)
