namespace :immosquare_cleaner do
  ##============================================================##
  ## Function to clean translation files in rails app
  ##============================================================##
  desc "Clean translation files in rails app"
  task :clean => :environment do
    file_paths = Dir.glob("#{Rails.root}/**/*").reject do |file_path|
      test1 = file_path.gsub("#{Rails.root}/", "")
      File.directory?(file_path) ||
        test1.start_with?("node_modules", "tmp", "public", "log", "app/assets/builds", "app/assets/fonts", "app/assets/images") ||
        file_path.end_with?(".lock", ".lockb")
    end
    file_paths.each do |file|
      puts file
      ImmosquareCleaner.clean(file)
    end
  end
end
