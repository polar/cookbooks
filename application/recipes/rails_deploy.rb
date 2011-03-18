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

include_recipe "application::rails_setup"
include_recipe "application::rails_database"

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
  # Take owner and group of app as defaults
  # NB: Hash should have a slice method based on keys.
  params = Mash.new({ "run_migrations" => false })
  params.merge!( "app_environment" => node.app_environment )
  params.merge!(get(app,'owner','group','force'))
  # any higher level gems have already been requested.
  # and searching for "bundler" only applies to this rails app.
  params.merge!(:gems => Mash.new)
  params.merge!(get(rails,'owner','group','force','gems','directory'))
  params.merge!(rails[:deploy])

  #
  # Deploys the app from the repository
  #
  ## NB: where the hell is this defined?
  deploy_revision app['id'] do
    revision     params['revision'][params['app_environment']]
    repository   params['repository']
    user         params['owner']
    group        params['group']
    deploy_to    params['directory']
    environment  'RAILS_ENV' => params['app_environment']
    action       params['force'][params['app_environment']] ? :force_deploy : :deploy
    ssh_wrapper  "#{params['directory']}/deploy-ssh-wrapper" if params['deploy_key']

    before_migrate do
      if params['gems'].has_key?('bundler')
        link "#{release_path}/vendor/bundle" do
          to "#{params['directory']}/shared/vendor_bundle"
        end
        common_groups = %w{development test cucumber staging production}
        execute "bundle install --deployment --without #{(common_groups -([params['app_environment']])).join(' ')}" do
          ignore_failure true
          cwd release_path
        end
      elsif params['gems'].has_key?('bundler08')
        execute "gem bundle" do
          ignore_failure true
          cwd release_path
        end

      elsif
        # chef runs before_migrate, then symlink_before_migrate symlinks, then migrations,
        # yet our before_migrate needs database.yml to exist (and must complete before
        # migrations).
        #
        # maybe worth doing run_symlinks_before_migrate before before_migrate callbacks,
        # or an add'l callback.

        shared_db_config = "../../../shared/database.yml"

        if ::File.exists?(shared_db_config)
          execute("ln -s #{shared_db_config} config/database.yml") do
            ignore_failure true
            cwd release_path
          end
        end

        execute("rake gems:install") do
          cwd release_path
        end

        if ::File.exists?(shared_db_config)
          execute("rm config/database.yml") do
            ignore_failure true
            cwd release_path
          end
        end
      end

      # Don't create symlinks if doing so would replace an existing file
      # with a link to nowhere.

      new_resource.symlink_before_migrate.delete_if do |src, dst|
        !(::File.exists?("#{new_resource.shared_path}/#{src}")) &&
        ::File.exists?("#{release_path}/#{dst}")
      end
    end

    symlink_before_migrate({
      "database.yml" => "config/database.yml",
      "memcached.yml" => "config/memcached.yml"
    })

    if params['migrate'][params['app_environment']] && params['run_migrations']
      migrate true
      migration_command params['migration_command'] || "rake db:migrate"
    else
      migrate false
    end
    before_symlink do
      ruby_block "remove_run_migrations" do
        block do
          if node.role?("#{app['id']}_run_migrations")
            Chef::Log.info("Migrations were run, removing role[#{app['id']}_run_migrations]")
            node.run_list.remove("role[#{app['id']}_run_migrations]")
          end
        end
      end
    end
  end
end
