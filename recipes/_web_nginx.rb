template "/opt/graphite/webapp/wsgi.py" do
  backup false
  mode '0755'
  source 'wsgi.py.erb'
end

directory "/etc/uwsgi/" do
  action :create
end

template "/etc/uwsgi/graphite.ini" do
  backup false
  mode '0644'
  source 'uwsgi.ini.erb'
end

template "/etc/nginx/sites-available/graphite" do
  backup false
  mode "0644"
  source "nginx-site-available.erb"
end

nginx_site "graphite" do
  enable true
end

graphite_uwsgi = supervisord_program "graphite_uwsgi" do
  command "uwsgi /etc/uwsgi/graphite.ini"
  autostart true
  action [:supervise, :start]
end

ruby_block "start graphite uwsgi" do
  block do
    graphite_uwsgi.run_action(:start)
  end
end
