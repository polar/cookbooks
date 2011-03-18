#
# Single Rails/Unicorn/Nginx application stack
#

include_recipe "application::packages"
include_recipe "application::gems"
include_recipe "application::users"
include_recipe "application::directories"
include_recipe "application::rails_deploy"
include_recipe "application::unicorn"
include_recipe "application::nginx"
include_recipe "application::runit_unicorn_nginx"