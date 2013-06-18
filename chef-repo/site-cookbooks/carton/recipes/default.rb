#
# Cookbook Name:: carton
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "perl"

bash "install carton" do
  not_if 'which carton'
  code <<-EOC
    PERL_CPANM_HOME=/tmp/cpanm-build
    curl -kL http://cpanmin.us | perl - --dev -n Carton
  EOC
end
