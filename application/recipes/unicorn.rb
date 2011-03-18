
include_recipe "unicorn"

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

    params = get(app,'owner','group','directories')
    params["worker_timeout"] = 60
    params["preload_app"] = false
    params["worker_processes"] = [node[:cpu][:total].to_i * 4, 8].min
    params["preload_app"] = false
    params["before_fork"] = 'sleep 1'
    params["listen"] = 8080
    params["command"] = "unicorn_rails" # Pre Rack Rails
    params["listen_options"] = { :tcp_nodelay => true, :backlog => 100 }
    params.merge!(app[:unicorn])

    if !params[:conf_file]
      params[:conf_file] = "#{params[:directories][:conf_dir]}/unicorn.rb"
      ## Not sure if I can do this and have it passed to later
      ## applications.
      app[:unicorn][:conf_file] = params[:conf_file]
    end
  # Defined in the Unicorn Recipe
  unicorn_config "#{params[:directories][:conf_dir]}/unicorn.rb" do

    listen             params["listen"] => params['listen_options']
    working_directory  params['working_directory']
    worker_timeout     params["worker_timeout"]
    preload_app        params["preload_app"]
    worker_processes   params["worker_processes"]
    before_fork        params["before_fork"]
  end

  file "#{params[:directories][:conf_dir]}/unicorn.rb" do
    owner params[:owner]
    group params[:group]
    mode 0755
  end