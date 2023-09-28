module ImmosquareCleaner
  class Railtie < Rails::Railtie

    rake_tasks do
      load "tasks/Immosquare-cleaner.rake"
    end

  end
end