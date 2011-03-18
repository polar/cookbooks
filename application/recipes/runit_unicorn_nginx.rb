
include_recipe "runit"

#
# Sometimes the Ruby People are just idiots.
# WTF does select and reject not return a Hash? Idiots.
#
  def get(hash, *keys)
    eat = Mash.new
    hash.each_key {|k| eat[k]=hash[k] if keys.include?(k)}
    return eat
  end

app = node.run_state[:current_app]

  params = Mash.new
  params.merge!(get(app, 'owner','group'))
  params.merge!(:app_environment => node[:app_environment])
  params.merge!(:app_name => app[:id] )
  params.merge!(:conf_dir => app[:directories][:conf_dir])
  params.merge!(:app_environment => node[:app_environment])
  params.merge!(:unicorn => app[:unicorn])
  params.merge!(:nginx => app[:nginx])

  runit_service "#{params[:app_name]}_unicorn" do
    # this finds some hidden template named "sv-unicorn-run.erb"
    template_name 'unicorn'
    cookbook 'application'
    options(
      :app_name => params[:app_name],
      :owner => params[:owner],
      :group => params[:group],
      :command => params[:unicorn][:command],
      :working_directory => params[:unicorn][:working_directory],
      :conf_file => params[:unicorn][:conf_file],
      :app_evnvironment => params[:app_envionment]
    )
    run_restart false
  end

  runit_service "#{params[:app_name]}_nginx" do
    # this finds some hidden template named "sv-#{name}-nginx.erb"
    template_name 'nginx'
    cookbook 'application'
    options(
      :app_name => params[:app_name],
      :binary => node[:nginx][:binary],
      :conf_file => params[:nginx][:conf_file]
    )
    run_restart false
  end

  ## I don't know what resources does.
  d = resources(:deploy => params[:app_name])
  if d
    d.restart_command do
      execute "/etc/init.d/#{params[:app_name]}_unicorn hup"
      execute "/etc/init.d/#{params[:app_name]}_nginx hup"
    end
  end