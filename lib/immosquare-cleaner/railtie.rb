module ImmosquareYaml
  class Railtie < Rails::Railtie

    rake_tasks do
      load "tasks/immosquare-cleaner.rake"
    end

  end
end
