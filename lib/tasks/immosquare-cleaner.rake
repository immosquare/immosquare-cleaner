namespace :immosquare_cleaner do
  
  ##============================================================##
  ## Function to clean translation files in rails app
  ##============================================================##
  desc "Clean translation files in rails app"
  task :clean => :environment do
    Dir.glob("#{Rails.root}/*").each do |file|
      ImmosquareCleaner.clean(file)
    end
  end
  
end