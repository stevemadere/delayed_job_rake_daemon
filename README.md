# Capistrano::DelayedJob
==========

Workaround for a nasty gem interaction bug in the DelayedJob job worker script.

For many users of DelayedJob, they are finding that they can run this command and it works just fine:
``` bash
   rake jobs:work
```

However, the script provided by DelayedJob to run in the background has unrecoverable errors in its postgres connection and the rake command does not run in the background.  As such, they are finding that they cannot deploy with capistrano and get their job worker automatically restarted on deploy.

See this for a detailed explanation of the problem:
[http://stackoverflow.com/questions/26515765/weird-interaction-of-delayed-job-daemons-koala-pg]

The admittedly hacky solution offered in this gem is to create a daemon runner/manager script which manages *rake jobs:work* running as a daemon.

If you use a combination of the _pg_ and _koala_ gms in your delayed jobs,  you are very likely to need *delayed_job_rake_daemon*


## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'delayed_job_rake_daemon'
```

This installs delayed_job_rake_daemon so that it can be run under the bundler (important for ease of deployment with capistrano).

Next, if you are using Capistano for deployment, add the following to your config/deploy.rb:

``` ruby
namespace :delayed_job do
  desc "Restart delayed_job worker daemon"
  task :restart do
    on roles :worker do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # specifying bundle exec is necessary to get rvm environment initialzed by capistrano-rvm
          execute :bundle, 'exec', 'delayed_job_rake_daemon', 'restart'
        end
      end
    end
  end
end

namespace :deploy do
  after :finshing 'delayed_job:restart'
end

```
You will also need to add the *:worker* role to some server.  e.g.:
``` ruby
role :worker, %w{deployer@jobworker.mydomain.com}
```


