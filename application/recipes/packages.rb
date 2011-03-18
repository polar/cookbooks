#
# Initializes for the application
#
app = node.run_state[:current_app]

  if app['packages']
    app['packages'].each do |pkg,ver|
      package pkg do
        action :install
        version ver if ver && ver.length > 0
      end
    end
  end

  package "rails"
