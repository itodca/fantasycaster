# RVM

$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
set :rvm_ruby_string, 'default'
set :rvm_type, :user

# General

set :application, "fantasycaster"
set :user, "rails"

set :path, "/home/#{user}/#{application}"
set :deploy_to, "#{path}"
set :deploy_via, :copy

set :use_sudo, false

# Git

set :scm, :git
set :repository,  "~/Sites/fantasycaster/.git"
set :branch, "master"

# VPS

role :web, "96.126.107.104"
role :app, "96.126.107.104"
role :db,  "96.126.107.104", :primary => true
role :db,  "96.126.107.104"

# Passenger

namespace :deploy do
 task :start do ; end
 task :stop do ; end
 task :restart, :roles => :app, :except => { :no_release => true } do
   run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
 end
 
 namespace :db do
  
    desc "Syncs the database.yml file from the local machine to the remote machine"
    task :sync_yaml do
      puts "\n\n=== Syncing database yaml to the production server! ===\n\n"
      unless File.exist?("config/database.yml")
        puts "There is no config/database.yml.\n "
        exit
      end
      system "rsync -vr --exclude='.DS_Store' config/database.yml #{user}@#{application}:#{shared_path}/config/"
    end
    
    desc "Clear Database Sessions"
    task :clear_sessions do
      puts "\n\n=== Clearing Database Sessions! ===\n\n"
      run "cd #{current_path}; rake db:sessions:clear RAILS_ENV=production"
    end
    
    desc "Create Production Database"
    task :create do
      puts "\n\n=== Creating the Production Database! ===\n\n"
      run "cd #{current_path}; rake db:create RAILS_ENV=production"
    end
  
    desc "Migrate Production Database"
    task :migrate do
      puts "\n\n=== Migrating the Production Database! ===\n\n"
      run "cd #{current_path}; rake db:migrate RAILS_ENV=production"
    end

    desc "Resets the Production Database"
    task :migrate_reset do
      puts "\n\n=== Resetting the Production Database! ===\n\n"
      run "cd #{path}; rake db:migrate:reset RAILS_ENV=production"
    end
    
    desc "Destroys Production Database"
    task :drop do
      puts "\n\n=== Destroying the Production Database! ===\n\n"
      run "cd #{current_path}; rake db:drop RAILS_ENV=production"
    end

    desc "Moves the SQLite3 Production Database to the shared path"
    task :move_to_shared do
      puts "\n\n=== Moving the SQLite3 Production Database to the shared path! ===\n\n"
      run "mv #{current_path}/db/production.sqlite3 #{shared_path}/db/production.sqlite3"
    end
  
    desc "Populates the Production Database"
    task :seed do
      puts "\n\n=== Populating the Production Database! ===\n\n"
      run "cd #{current_path}; rake db:seed RAILS_ENV=production"
    end
  
  end
 
 namespace :gems do
    
    desc "Installs any 'not-yet-installed' gems on the production server or a single gem when the gem= is specified."
    task :install do
      if ENV['gem']
        puts "\n\n=== Installing #{ENV['gem']}! ===\n\n"
        run "gem install #{ENV['gem']}"
      else
        puts "\n\n=== Installing required RubyGems! ===\n\n"
        run "cd #{current_path}; bundle install --path RAILS_ENV=production"
      end 
    end

  end
  
  namespace :nginx do
    
    desc "Restarts NginX."
    task :restart do
      run "cd #{current_path}; service nginx restart"
    end

  end
  
  desc "precompile the assets"
  task :precompile_assets, :roles => :web, :except => { :no_release => true } do
    run "cd #{current_path}; rm -rf public/assets/*"
    run "cd #{current_path}; rake assets:precompile RAILS_ENV=production"
  end
end

#~ after 'deploy:update_code' do
  #~ run "cd #{release_path}; RAILS_ENV=production bundle exec rake assets:precompile"
#~ end
