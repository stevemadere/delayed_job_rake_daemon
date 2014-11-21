require 'minitest/autorun'


class FakeBundleEnv
  require 'fileutils'
  require 'pathname'

  def initialize
    @temp_dir = Pathname.new(Dir.mktmpdir)
    @old_path = ENV['PATH']
    FileUtils.mkdir_p(fake_bin_dir)
    create_fake_bundle
    ENV['PATH'] = [fake_bin_dir.to_s,@old_path].join(':')
    confirm_fake_bundle
    yield self
  ensure
    cleanup
  end

  attr_reader :temp_dir

  def bundle_running?
    return false unless File.exist?(running_indicator_file)
    bundle_pid = IO.read(running_indicator_file).to_i
    running = false
    begin
      Process.kill(0,bundle_pid)
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
      temp_dir.join('bundle_running')
    end

    def create_fake_bundle
      bundle_script = fake_bundle
      File.open(bundle_script,'w') do |f|
        f.puts <<-"EOSCRIPT"
        while true
        do
          echo $$ > '#{running_indicator_file}'
          sleep 1
        done
        EOSCRIPT
      end
      system("chmod og-w #{bundle_script} && chmod +x #{bundle_script}")
    end

    def fake_bundle
      bundle_script = fake_bin_dir.join('bundle')
    end

    def confirm_fake_bundle
      which = `which bundle`
      raise "bundle resolves to #{which} instead of #{fake_bundle}" unless which.to_s.strip == fake_bundle.to_s.strip
    end

    def cleanup
      ENV['PATH'] = @old_path
      #puts "temp dir path is #{temp_dir}"
      FileUtils.remove_entry_secure(temp_dir)
    end

end

describe "delayed_job_rake_daemon" do

  it "has a working FakeBundleEnv fixture" do
    FakeBundleEnv.new do |fre|
      assert(!fre.bundle_running?)
      if child_pid = Process.fork 
        sleep 1
        was_running_before_killed = fre.bundle_running?
        Process.kill(9,child_pid)
        Process.waitpid(child_pid)
        assert(was_running_before_killed)
        assert(!fre.bundle_running?)
      else
        Process.exec('bundle exec rake stuff')
      end
    end
  end

  it "starts/stops the daemon" do
    djrd = Pathname(__FILE__).dirname.join('..','bin','delayed_job_rake_daemon')
    puts "djrd is #{djrd}"
    assert(File.exists?(djrd))
    FakeBundleEnv.new do |fre|
      Dir.chdir(fre.temp_dir) do
        system("#{djrd} start")
        sleep 1
        assert(fre.bundle_running?)
        system("#{djrd} stop")
        assert(!fre.bundle_running?)
      end
     end
  end
end
