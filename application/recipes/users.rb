#
# Recipe for setting the required users and groups
# for a Rails/Unicorn/NginX application.
#

app = node.run_state[:current_app]

users = app[:users]
groups = app[:groups]

  groups.each do |grp|
    group grp[:name] do
      gid grp[:gid].to_i
    end
  end

  users.each do |usr|
    user usr[:name] do
      uid usr[:uid].to_i
      gid usr[:gid].to_i
      shell usr[:shell]
      password usr[:password]
      home usr[:home]
      supports :manage_home => true
    end
    if usr[:memberof]
      usr[:memberof].each do |grp|
        group grp do
          members [usr[:name]]
          append true
        end
      end
    end
  end