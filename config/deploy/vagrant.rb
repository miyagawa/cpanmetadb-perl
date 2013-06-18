set :user, "vagrant"
server "cpanmetadb-vagrant", :app, :web
set :deploy_to, "/home/vagrant/apps/cpanmetadb-perl"
set :app_port, 5000

