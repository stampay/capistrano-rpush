require 'capistrano/bundler'
require 'capistrano/plugin'

module Capistrano
  module RpushCommon
    def rpush_switch_user(role, &block)
      user = rpush_user(role)
      if user == role.user
        block.call
      else
        as user do
          block.call
        end
      end
    end

    def rpush_user(role)
      properties = role.properties
      properties.fetch(:rpush_user) ||  # local property for rpush only
      fetch(:rpush_user) ||
      properties.fetch(:run_as) ||      # global property across multiple capistrano gems
      role.user
    end
  end

  class Rpush < Capistrano::Plugin
    include RpushCommon

    def define_tasks
      eval_rakefile File.expand_path('../tasks/rpush.rake', __FILE__)
    end

    def set_defaults
      set_if_empty :rpush_default_hooks, true
      set_if_empty :rpush_role,          :app
      set_if_empty :rpush_env,           -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
      set_if_empty :rpush_conf,          -> { File.join(current_path, 'config', 'initializers', 'rpush.rb') }
      set_if_empty :rpush_log,           -> { File.join(shared_path, 'log', 'rpush.log') }
      set_if_empty :rpush_pid,           -> { File.join(shared_path, 'tmp', 'pids', 'rpush.pid') }

      append :rbenv_map_bins, 'rpush'
      append :bundle_bins, 'rpush'
    end

    def register_hooks
      after 'deploy:check',    'rpush:check'
      after 'deploy:finished', 'rpush:restart'
    end
  end
end
