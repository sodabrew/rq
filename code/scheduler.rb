require 'socket'
require 'json'
require 'fcntl'
require 'fileutils'
require 'code/unixrack'
require 'code/hashdir'

module RQ
  class Scheduler

    def initialize(options, parent_pipe)
      @start_time = Time.now
      # Read config
      @name = "scheduler"
      @sched_path = "scheduler/"
      @rq_config_path = "./config/"
      @parent_pipe = parent_pipe
      init_socket

      @config = {}

      @status = {}
      @status["admin_status"] = "UP"
      @status["oper_status"]  = "UP"

      if load_rq_config == nil
        sleep 5
        log("Invalid main rq config. Exiting." )
        exit! 1
      end

      if load_config == false
        sleep 5
        log("Invalid config for #{@name}. Skipping." )
        #exit! 1
      end
    end

    def self.log(path, mesg)
      File.open(path + '/sched.log', "a") do |f|
        f.write("#{Process.pid} - #{Time.now} - #{mesg}\n")
      end
    end

    def self.start_process(options)
      # nice pipes writeup
      # http://www.cim.mcgill.ca/~franco/OpSys-304-427/lecture-notes/node28.html
      child_rd, parent_wr = IO.pipe

      child_pid = fork do
        # Restore default signal handlers from those inherited from queuemgr
        Signal.trap('TERM', 'DEFAULT')
        Signal.trap('CHLD', 'DEFAULT')

        sched_path = "scheduler/"
        $0 = "[rq-scheduler]"
        begin
          parent_wr.close
          #child only code block
          RQ::Scheduler.log(sched_path, 'post fork')

          Daemons.close_io

          q = RQ::Scheduler.new(options, child_rd)
          # This should never return, it should Kernel.exit!
          # but we may wrap this instead
          RQ::Scheduler.log(sched_path, 'post new')
          q.run_loop
        rescue Exception
          self.log(sched_path, "Exception!")
          self.log(sched_path, $!)
          self.log(sched_path, $!.backtrace)
          raise
        end
      end

      #parent only code block
      child_rd.close

      if child_pid == nil
        parent_wr.close
        return nil
      end

      [child_pid, parent_wr]
    end

    def init_socket
      # Show pid
      File.unlink(@sched_path + '/sched.pid') rescue nil
      File.open(@sched_path + '/sched.pid', "w") do
        |f|
        f.write("#{Process.pid}\n")
      end

      # Setup IPC
      File.unlink(@sched_path + '/sched.sock') rescue nil
      @sock = UNIXServer.open(@sched_path + '/sched.sock')
    end

    def load_rq_config
      begin
        data = File.read(@rq_config_path + 'config.json')
        js_data = JSON.parse(data)
        @host = js_data['host']
        @port = js_data['port']
      rescue
        return nil
      end
      return js_data
    end

    def load_config
      begin
        data = File.read(@sched_path + '/config.json')
        @config = JSON.parse(data)
      rescue
        return false
      end
      return true
    end

    def log(mesg)
      File.open(@sched_path + '/sched.log', "a") do |f|
        f.write("#{Process.pid} - #{Time.now} - #{mesg}\n")
      end
    end

    def run_loop
      Signal.trap("TERM") do
        log("received TERM signal")
        # TODO: write_status
        exit 0
      end

      while true
        sleep 60
      end
    end

  end
end


