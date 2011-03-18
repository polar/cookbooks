#
# Recipe for setting configuration, log, and run
# directories up a Rails/Unicorn/NginX application.
#

app = node.run_state[:current_app]

dirs = app[:directories]

  directory dirs[:log_dir] do
    mode 0755
    owner app[:owner]
    group app[:group]
    action :create
    recursive true
  end

  directory dirs[:conf_dir] do
    mode 0755
    owner app[:owner]
    group app[:group]
    action :create
    recursive true
  end

  directory dirs[:run_dir] do
    mode 0755
    owner app[:owner]
    group app[:group]
    action :create
    recursive true
  end
