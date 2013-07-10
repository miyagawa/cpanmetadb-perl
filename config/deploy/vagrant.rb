set :use_sudo, false
set :user, "vagrant"
server "fidi", :app, :web
set :deploy_to, "/home/vagrant/apps/cpanmetadb-perl"
set :app_port, 5000

