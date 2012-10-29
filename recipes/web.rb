version = node[:graphite][:version]
pyver = node[:graphite][:python_version]

package "python-cairo-dev"
package "python-django"
package "python-django-tagging"
package "python-memcache"
package "python-rrdtool"

remote_file "/usr/src/graphite-web-#{version}.tar.gz" do
  source node[:graphite][:graphite_web][:uri]
  checksum node[:graphite][:graphite_web][:checksum]
end

execute "untar graphite-web" do
  command "tar xzf graphite-web-#{version}.tar.gz"
  creates "/usr/src/graphite-web-#{version}"
  cwd "/usr/src"
end

execute "install graphite-web" do
  command "python setup.py install"
  creates "/opt/graphite/webapp/graphite_web-#{version}-py#{pyver}.egg-info"
  cwd "/usr/src/graphite-web-#{version}"
end

case node["graphite"]["webserver_flavour"]
when "nginx"
  include_recipe 'graphite::_web_nginx'
  owner = node['nginx']['user']
  group = node['nginx']['group']
else
  include_recipe 'graphite::_web_apache'
  owner = node['apache']['user']
  group = node['apache']['group']
end

directory "/opt/graphite/storage" do
  owner owner
  group group
end

directory '/opt/graphite/storage/log' do
  owner owner
  group group
end

%w{ webapp whisper }.each do |dir|
  directory "/opt/graphite/storage/log/#{dir}" do
    owner owner
    group group
  end
end

cookbook_file "/opt/graphite/bin/set_admin_passwd.py" do
  mode "755"
end

cookbook_file "/opt/graphite/storage/graphite.db" do
  action :create_if_missing
  notifies :run, "execute[set admin password]"
end

execute "set admin password" do
  command "/opt/graphite/bin/set_admin_passwd.py root #{node[:graphite][:password]}"
  action :nothing
end

file "/opt/graphite/storage/graphite.db" do
  owner owner
  group group
  mode "644"
end
