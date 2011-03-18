#
# Initializes for the application
#
app = node.run_state[:current_app]

  if app['gems']
    app['gems'].each do |gem,ver|
        gem_package gem do
          action :install
          version ver if ver && ver.length > 0
        end
    end
  end