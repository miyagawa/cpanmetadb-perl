set :user, "web"
server "fidi-tokyo.plackperl.org", :app, :web
set :deploy_to, "/home/web/apps/cpanmetadb-perl"
set :app_port, 5000
