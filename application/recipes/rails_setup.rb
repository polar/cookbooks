#
# Cookbook Name:: application
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Sets up the rails deployment directory strategy for the app

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

if rails[:deploy]
  puts "Eatme"
  # Take owner and group of app as defaults
  # NB: Hash should have a slice method based on keys.
  params = Mash.new({ "deploy_to" => rails[:directory] })
  params.merge!(get(app,'owner','group'))
  params.merge!(get(rails,'owner','group'))
  params.merge!(app[:rails][:deploy])

  if params.has_key?("deploy_key")
    ruby_block "write_key" do
      block do
        f = ::File.open("#{params['deploy_to']}/id_deploy", "w")
        f.print(params["deploy_key"])
        f.close
      end
      not_if do ::File.exists?("#{params['deploy_to']}/id_deploy"); end
    end

    file "#{params['deploy_to']}/id_deploy" do
      owner params['owner']
      group params['group']
      mode '0600'
    end

    template "#{params['deploy_to']}/deploy-ssh-wrapper" do
      source "deploy-ssh-wrapper.erb"
      owner params['owner']
      group params['group']
      mode "0755"
      variables params.to_hash
    end
  end
end

