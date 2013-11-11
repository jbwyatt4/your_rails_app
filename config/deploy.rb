require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)

set :domain, '33.33.13.39'
set :user, 'user'
set :deploy_to, '/var/www/your_rails_app'
set :repository, 'http://github.com/jbwyatt4/your_rails_app.git'
set :rvm_path, '/etc/profile.d/rvm.sh'
set :rvm_gemset, 'ruby-1.9.3-p448@default'
set :shared_paths, ['config/database.yml', 'log']

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/database.yml'."]
end

task :environment do
  invoke :'rvm:use["ruby-1.9.3-p448@default"]'
  #invoke :'rvm:use[#{:rvm_gemset}]'
end

task :restart do
  # How to restart Passenger
 queue 'sudo touch /tmp/restart'
end

# The => notation means 'environment' gets run before the deploy task.
task :deploy => :environment do
  deploy do
    # Put things that prepare the empty release folder here.
    # Commands queued here will be ran on a new release directory.
    #invoke :'rvm:use[ruby-1.9.3-p448@default]'
    invoke :'git:clone'
    # Overrides the database file every time it's deployed
    invoke :'deploy:link_shared_paths'
    #queue! %[cp "#{deploy_to}/current/config/database.yml" "#{deploy_to}/shared/config/database.yml"]
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    #invoke :'rails:assets_precompile'
    # These are instructions to start the app after it's been prepared.
    #to :launch do
    #  queue 'touch tmp/restart.txt'
    #end

    # This optional block defines how a broken release should be cleaned up.
    #to :clean do
    #  queue 'log "failed deployment"'
    #end
  end
end

desc "Shows logs."
task :logs do
  queue %[cd #{deploy_to!} && tail -f logs/error.log]
end