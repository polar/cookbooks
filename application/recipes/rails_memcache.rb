
include_recipe "application::rails_directories"

app = node.run_state[:current_app]
rails = app[:rails]

  if app["memcached_role"]
    results = search(:node, "role:#{app["memcached_role"][0]} AND app_environment:#{node[:app_environment]} NOT hostname:#{node[:hostname]}")
    if results.length == 0
      if node.run_list.roles.include?(app["memcached_role"][0])
        results << node
      end
    end
    template "#{app['deploy_to']}/shared/memcached.yml" do
      source "memcached.yml.erb"
      owner app["owner"]
      group app["group"]
      mode "644"
      variables(
        :memcached_envs => app['memcached'],
        :hosts => results.sort_by { |r| r.name }
      )
    end
  end
