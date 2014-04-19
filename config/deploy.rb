require 'rvm/capistrano'
set :application, "rails3deployment"
set :rails_env, 'production'

set :scm, :git
set :repository, "git@github.com:dprabu17/rails3_deployments.git"
set :rvm_type, :system
#set :branch, fetch(:branch, "capistrano")
set :env, fetch(:env, "production")
set :normalize_asset_timestamps, false #turn off default behavior /public/images

set :deploy_via, :remote_cache
set :deploy_to, "/home/webapps/www/#{application}"


set :copy_dir, "/home/prabu/tmp"
set :remote_copy_dir, "/tmp" 
set :use_sudo, false

role :web, "188.226.210.218"                          # Your HTTP server, Apache/etc
role :db,  "188.226.210.218", :primary => true # This is where Rails migrations will run
set :user, "deployer"
#set :scm_passphrase, "deployer"  # The deploy user's password
default_run_options[:pty] = true #Must be set for the password prompt

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  desc "Restart the application"
  task :restart, :roles => :web, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  #run assets precompile
namespace :assets do
  task :precompile, :roles => :web, :except => {:no_release => true} do
      run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env}  assets:precompile}
  end
end

end
namespace :bundle do

  desc "run bundle install and ensure all gem requirements are met"
  task :install do
    run "cd #{current_path} && bundle install "
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

after "deploy:restart", "deploy:cleanup"
before "deploy:restart", "copy_in_database_yml"
before "deploy:restart", "deploy:assets:precompile"
before "deploy:restart", "run_migrations"
before 'deploy:finalize_update', 'bundle:install'
