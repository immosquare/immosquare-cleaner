namespace :immosquare_cleaner do
  ##============================================================##
  ## Function to clean files in rails app
  ##============================================================##
  desc "clean files in rails app"
  task :clean_app => :environment do
    paths_to_exclude = [
      "app/assets/builds",
      "app/assets/fonts",
      "app/assets/images",
      "coverage",
      "log",
      "node_modules",
      "public",
      "test",
      "tmp",
      "vendor"
    ]
    extensions_to_exclude = [
      ".lock",
      ".lockb"
    ]
    file_paths = Dir.glob("#{Rails.root}/**/*").reject do |file_path|
      File.directory?(file_path) || file_path.gsub("#{Rails.root}/", "").start_with?(*paths_to_exclude) || file_path.end_with?(*extensions_to_exclude)
    end

    puts("Cleaning files...")

    file_paths.each.with_index do |file_path, index|
      puts("#{index + 1}/#{file_paths.size} - #{file_path}")
      ImmosquareCleaner.clean(file_path)
    end
  end
end
