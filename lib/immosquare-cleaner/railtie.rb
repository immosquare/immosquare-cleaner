module ImmosquareCleaner
  class Railtie < Rails::Railtie

    rake_tasks do
      load("tasks/immosquare_cleaner.rake")
    end

  end
end
