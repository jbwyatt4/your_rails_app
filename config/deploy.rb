require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)

set :domain, '33.33.13.40'
set :user, 'user'
set :webroot, '/var/www'
set :app_name, 'your_rails_app'
set :deploy_to, "#{webroot}/#{app_name}"
set :repository, 'http://github.com/jbwyatt4/your_rails_app.git'
set :rvm_path, '/etc/profile.d/rvm.sh'
set :rvm_gemset, 'ruby-1.9.3-p448@default'
set :shared_paths, ['log', 'config/application.yml']
set :term_mode, nil # needed to solve a login problem

# If your using the rails bluebook recipe with Mina
# for the first time, use this task with:
# mina cold_start --verbose
tast :cold_start do
  # You call other Mina (Rake) tasks with invoke.
  invoke :'setup'
  invoke :'deploy'
  invoke :'hard_restart'
  queue! %[echo "Mina has deployed #{app_name}!"]
end

# Setup a shared folder so logs and the application.yml
# can be shared between different versions of the app.
# If you attempt to copy the application.yml w/o a shared
# link you will get permission errors.
task :setup => :environment do
  # create shared folders and set permissions
  # The ! tells Mina to print out the terminal output.
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[touch "#{deploy_to}/shared/config/application.yml"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config/application.yml"]
end

# Wipe out the deploy
task :wipe do
  queue! %[rm -rf "#{deploy_to}"]
end

# Sometimes a deploy can be corrupted when
# your testing it out.
# Use this command to restart fresh.
task :rebuild do
  invoke :'wipe'
  invoke :'setup'
  invoke :'deploy'
  invoke :'hard_restart'
  queue! %[echo "Mina rebuilt #{app_name}!"]
end

# Sets our gem environment
task :environment do
  invoke :"rvm:use[#{rvm_gemset}]"
end

task :restart do
  # How to restart Passenger
  queue 'sudo touch /tmp/restart'
end

# When Nginx and Passenger are stubborn
task :hard_restart do
  queue 'sudo reboot'
end

# The => notation means 'environment' gets run before the deploy task.
task :deploy => :environment do
  deploy do
    # Put things that prepare the empty release folder here.
    # Commands queued here will be ran on a new release directory.
    invoke :'git:clone'

    # We linked the shared folder based on the shared_paths variable.
    invoke :'deploy:link_shared_paths'
    # Copy the application.yml file
    queue! %[cp "#{webroot}/application.yml" "#{deploy_to}/shared/config/application.yml"]
    queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config/application.yml"]

    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
  end
end

desc "Shows logs."
task :logs do
  queue %[cd #{deploy_to!} && tail -f logs/error.log]
end
