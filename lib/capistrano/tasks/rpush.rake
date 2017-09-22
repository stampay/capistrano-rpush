namespace :rpush do
  desc 'Check if config file exists'
  task :check do
    on roles (fetch(:rpush_role)) do |role|
      unless  test "[ -f #{fetch(:rpush_conf)} ]"
        warn 'rpush.rb NOT FOUND!'
        info 'Configure rpush for your project before attempting a deployment.'
      end
    end
  end

  desc 'Restart rpush'
  task :restart do
    on roles (fetch(:rpush_role)) do |role|
      rpush_switch_user(role) do
        if test "[ -f #{fetch(:rpush_pid)} ]"
          invoke 'rpush:stop'
        end
        invoke 'rpush:start'
      end
    end
  end

  desc 'Start rpush'
  task :start do
    on roles (fetch(:rpush_role)) do |role|
      rpush_switch_user(role) do
        if test "[ -f #{fetch(:rpush_conf)} ]"
          info "using conf file #{fetch(:rpush_conf)}"
        else
          invoke 'rpush:check'
        end
        within current_path do
          with rack_env: fetch(:rpush_env) do
            execute :rpush, "start -p #{fetch(:rpush_pid)} -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
          end
        end
      end
    end
  end

  desc 'Status rpush'
  task :status do
    on roles (fetch(:rpush_role)) do |role|
      rpush_switch_user(role) do
        if test "[ -f #{fetch(:rpush_conf)} ]"
          within current_path do
            with rack_env: fetch(:rpush_env) do
              execute :rpush, "status -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
            end
          end
        end
      end
    end
  end

  desc 'Stop rpush'
  task :stop do
    on roles (fetch(:rpush_role)) do |role|
      rpush_switch_user(role) do
        if test "[ -f #{fetch(:rpush_pid)} ]"
          within current_path do
            with rack_env: fetch(:rpush_env) do
              execute :rpush, "stop -p #{fetch(:rpush_pid)} -c #{fetch(:rpush_conf)} -e #{fetch(:rpush_env)}"
            end
          end
        end
      end
    end
  end

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
