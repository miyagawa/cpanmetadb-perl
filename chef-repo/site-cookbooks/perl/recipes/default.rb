#
# Cookbook Name:: perl
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

%w[build-essential curl git].each do |pkg|
  package pkg
end

git "/tmp/perl-build" do
  repository "git://github.com/tokuhirom/Perl-Build.git"
  reference "master"
  action :checkout
end

bash "install-perl" do
  not_if "/usr/local/bin/perl -e 'use 5.016'"
  code <<-EOC
    cd /tmp/perl-build
    ./perl-build 5.16.3 /usr/local
  EOC
end
