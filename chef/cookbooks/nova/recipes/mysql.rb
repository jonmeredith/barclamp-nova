#
# Cookbook Name:: nova
# Recipe:: mysql
#
# Copyright 2010-2011, Opscode, Inc.
# Copyright 2011, Dell, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

include_recipe "mysql::client"

# find mysql server configured by mysql-client
env_filter = " AND mysql_config_environment:mysql-config-#{node[:nova][:db][:mysql_instance]}"
db_server = search(:node, "roles:mysql-server#{env_filter}")
# if we found ourself, then use us.
if db_server[0]['fqdn'] == node['fqdn']
  db_server = [ node ]
end

log "DBServer: #{db_server[0].mysql.api_bind_host}"

# Creates empty nova database
mysql_database "create #{node[:nova][:db][:database]} database" do
  host     db_server[0]['mysql']['api_bind_host']
  username "db_maker"
  password db_server[0]['mysql']['db_maker_password']
  database node[:nova][:db][:database]
  action :create_db
end

mysql_database "create nova database user" do
  host     db_server[0]['mysql']['api_bind_host']
  username "db_maker"
  password db_server[0]['mysql']['db_maker_password']
  database node[:nova][:db][:database]
  action :query
  sql "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON #{node[:nova][:db][:database]}.* TO '#{node[:nova][:db][:user]}'@'%' IDENTIFIED BY '#{node[:nova][:db][:password]}';"
end

execute "nova-manage db sync" do
  command "nova-manage db sync"
  action :run
end

# save data so it can be found by search
node.save

