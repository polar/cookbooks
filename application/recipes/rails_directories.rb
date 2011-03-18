
# Sets up the rails deployment directory strategy for the app

app = node.run_state[:current_app]

#
# Sometimes the Ruby People are just idiots.
# WTF does select and reject not return a Hash? Idiots.
#
  def get(hash, *keys)
    eat = Mash.new
    hash.each_key {|k| eat[k]=hash[k] if keys.include?(k)}
    return eat
  end

if !app[:rails].nil?

  # Take owner and group of app as defaults
  # NB: Hash should have a slice method based on keys.
  params = get(app, 'owner','group')
  params.merge!(app[:rails])

  directory params['directory'] do
    owner params['owner']
    group params['group']
    mode '0755'
    recursive true
  end

  directory "#{params['directory']}/shared" do
    owner params['owner']
    group params['group']
    mode '0755'
    recursive true
  end

  for dir in %w{ log pids system vendor_bundle } do
    directory "#{params['directory']}/shared/#{dir}" do
      owner params['owner']
      group params['group']
      mode '0755'
      recursive true
    end
  end

end