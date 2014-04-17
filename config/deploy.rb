#require 'capistrano/ext/multistage'
require "rvm/capistrano"
require "bundler/capistrano"
set :rails_env,             'production'
set :rvm_type,              :system
set :copy_exclude, [ '.git' ]
set :application, "rails3_deployment"
#set :stages, %w(production development test) 
#set :default_stage, "production"

set :scm, :git
set :normalize_asset_timestamps, false #turn off default behavior /public/images
set :repository, "git@github.com:dprabu17/rails3_deployments.git"
set :branch, fetch(:branch, "master")
set :env, fetch(:env, "production")
default_run_options[:pty] = true #Must be set for the password prompt
set :deploy_via, :remote_cache
set :deploy_to, "/home/webapps/www/rails3deployment"
set :backup_to, "/home/webapps/backups"

set :copy_dir, "/home/prabu/tmp"
set :remote_copy_dir, "/tmp" 
set :use_sudo, true

role :web, "188.226.210.218"                          # Your HTTP server, Apache/etc
role :app, "188.226.210.218"                          # This may be the same as your `Web` server
role :db,  "188.226.210.218", :primary => true # This is where Rails migrations will run
set :user, "deployer"
#set :scm_passphrase, "deployer"  # The deploy user's password




# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
# namespace :bundle do
#   desc "run bundle install and ensure all gem requirements are met"
#   task :install do
#     run "cd #{current_path} && bundle install "
#   end
# end

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  desc "Restart the application"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  #run assets precompile
namespace :assets do
  task :precompile, :roles => :web, :except => {:no_release => true} do
      run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env}  assets:precompile}
  end
end

end

desc "Run rake db migrate on server" 
task :run_migrations, :roles => :db do
    puts "RUNNING DB MIGRATIONS"
    run "cd #{current_path}; rake db:migrate RAILS_ENV=#{rails_env}"
  end
  
desc "Copy the database.yml file into the latest release"
task :copy_in_database_yml do
  run "cp #{shared_path}/config/database.yml #{latest_release}/config/"
end

desc "Create symbolic links for assets "
task :symlink_assets, roles: :web do
    run "rm -rf #{latest_release}/public/assets &&
    mkdir -p #{latest_release}/public &&
     mkdir -p #{shared_path}/assets &&
     ln -s #{shared_path}/assets #{latest_release}/public/assets"
  end

after "deploy:restart", "deploy:cleanup"
before "deploy:restart", "copy_in_database_yml"
#before "deploy:restart", "bundle:install"
before "deploy:restart", "deploy:assets:precompile"
before "deploy:restart", "run_migrations"

before 'deploy:finalize_update', 'symlink_assets'