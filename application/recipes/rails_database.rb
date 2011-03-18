
include_recipe "application::rails_directories"

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
rails = app[:rails]

  params = get(rails,'databases')
  params.merge!(get(app,'owner','group'))
  params.merge!(get(rails,'owner','group','directory'))

  if !params['databases'].empty?
    template "#{params['directory']}/shared/database.yml" do
      source "database.yml.erb"
      owner params["owner"]
      group params["group"]
      mode "644"
      variables(:databases => params['databases'])
    end
  end
