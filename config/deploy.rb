require 'capistrano/ext/multistage'

set :stages, %w(production vagrant)
set :default_stage, "production"

set :application, "cpanmetadb-perl"
set :repository,  "git://github.com/miyagawa/cpanmetadb-perl.git"

set :scm, :git
set :use_sudo, false
set :branch, ENV['BRANCH'] || "master"
set :deploy_via, :remote_cache

# http://stackoverflow.com/questions/3023857/capistrano-and-deployment-of-a-website-from-github
set :normalize_asset_timestamps, false

before "deploy:finalize_update", "carton:install"

namespace :carton do
  task :install do
    run "cd #{latest_release} && carton install --deployment --path=#{shared_path}/local 2>&1"
  end
end

namespace :deploy do
  task :start, :roles => :app do
    conf = "/etc/supervisor/conf.d/#{application}.conf"
    run "test -e #{conf} || (cp #{current_path}/config/supervisor/#{application}.conf #{conf} && supervisorctl restart)"
    run "supervisorctl start"
  end

  task :stop, :roles => :app do
    run "supervisorctl stop #{application}"
  end

  task :restart, :roles => :app do
    run "kill -HUP `cat #{shared_path}/pids/server_status.pid`"
  end
end
