#
# Cookbook Name:: capistrano-apps
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# to be used by capistrano with set :use_sudo, false
directory '/u/apps' do
  owner node['app']['user']
  group node['app']['group']
  mode '0775'
  action :create
  recursive true
end
