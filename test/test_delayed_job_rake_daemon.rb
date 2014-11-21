require 'minitest/autorun'


class FakeRakeEnv
  require 'fileutils'
  require 'pathname'

  def initialize
    @temp_dir = Pathname.new(Dir.mktmpdir)
    @old_path = ENV['PATH']
    FileUtils.mkdir_p(fake_bin_dir)
    create_fake_rake
    ENV['PATH'] = [fake_bin_dir.to_s,@old_path].join(':')
    confirm_fake_rake
    yield self
  ensure
    cleanup
  end

  attr_reader :temp_dir

  def rake_running?
    return false unless File.exist?(running_indicator_file)
    rake_pid = IO.read(running_indicator_file).to_i
    running = false
    begin
      Process.kill(0,rake_pid)
      running = true
    rescue Errno::ESRCH
      running = false
    end
    return running
  end

  protected


    def fake_bin_dir
      Pathname.new(temp_dir).join('bin')
    end

    def running_indicator_file
      temp_dir.join('rake_running')
    end

    def create_fake_rake
      rake_script = fake_rake
      File.open(rake_script,'w') do |f|
        f.puts <<-"EOSCRIPT"
        while true
        do
          echo $$ > '#{running_indicator_file}'
          sleep 1
        done
        EOSCRIPT
      end
      system("chmod og-w #{rake_script} && chmod +x #{rake_script}")
    end

    def fake_rake
      rake_script = fake_bin_dir.join('rake')
    end

    def confirm_fake_rake
      which = `which rake`
      raise "rake resolves to #{which} instead of #{fake_rake}" unless which.to_s.strip == fake_rake.to_s.strip
    end

    def cleanup
      ENV['PATH'] = @old_path
      #puts "temp dir path is #{temp_dir}"
      FileUtils.remove_entry_secure(temp_dir)
    end

end

describe "delayed_job_rake_daemon" do

  it "has a working FakeRakeEnv fixture" do
    FakeRakeEnv.new do |fre|
      assert(!fre.rake_running?)
      if child_pid = Process.fork 
        sleep 1
        was_running_before_killed = fre.rake_running?
        Process.kill(9,child_pid)
        Process.waitpid(child_pid)
        assert(was_running_before_killed)
        assert(!fre.rake_running?)
      else
        Process.exec('rake junk')
      end
    end
  end

  it "starts/stops the daemon" do
    djrd = Pathname(__FILE__).dirname.join('..','bin','delayed_job_rake_daemon')
    puts "djrd is #{djrd}"
    assert(File.exists?(djrd))
    FakeRakeEnv.new do |fre|
      Dir.chdir(fre.temp_dir) do
        system("#{djrd} start")
        sleep 1
        assert(fre.rake_running?)
        system("#{djrd} stop")
        assert(!fre.rake_running?)
      end
     end
  end
end
