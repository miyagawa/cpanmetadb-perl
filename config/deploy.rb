require 'capistrano/ext/multistage'

set :stages, %w(production vagrant)
set :default_stage, "production"

set :application, "cpanmetadb"
set :repository,  "git://github.com/miyagawa/cpanmetadb-perl.git"

set :scm, :git
set :use_sudo, false
set :branch, ENV['BRANCH'] || "master"
set :deploy_via, :remote_cache

# http://stackoverflow.com/questions/3023857/capistrano-and-deployment-of-a-website-from-github
set :normalize_asset_timestamps, false

set :pidfile, "#{shared_path}/pids/start_server.pid"
set :statusfile, "#{shared_path}/pids/start_server.status"

before "deploy:finalize_update", "carton:install"

namespace :carton do
  task :install do
    run "cd #{latest_release} && carton install --deployment --path=#{shared_path}/local 2>&1"
  end
end

namespace :deploy do
  def server_starter
    "cd #{current_path} && nohup carton exec start_server --port=#{app_port} --status-file=#{statusfile} --pid-file=#{pidfile}"
  end

  def run_server
    "#{server_starter} -- twiggy -I#{current_path}/lib --access-log=#{shared_path}/log/access_log #{current_path}/app-gw.psgi > #{shared_path}/log/start_server.log 2>&1"
  end

  def carton_env
    { "PERL_CARTON_PATH" => "#{shared_path}/local" }
  end

  task :start, :roles => :app do
    run "#{run_server} &", :env => carton_env
  end

  task :stop, :roles => :app do
    run "if [ -e #{pidfile} ]; then kill -s TERM `cat #{pidfile}`; rm #{pidfile}; fi"
  end

  task :restart, :roles => :app do
    run "if [ -e #{pidfile} ]; then #{server_starter} --restart; else (#{run_server} &); fi", :env => carton_env
  end
end
