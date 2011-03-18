# Recipe for getting Nginx

package "nginx"

node[:nginx] = { :binary => "/usr/sbin/nginx" }

app = node.run_state[:current_app]


  template "#{app[:conf_dir]}/nginx.conf" do
    source "rails_unicorn_nginx.conf.erb"
    owner app[:owner]
    group app[:group]
    variables :options => { :app => app }
    mode 0644
  end
