namespace :immosquare_cleaner do
  ##============================================================##
  ## Function to clean files in rails app
  ##============================================================##
  desc "clean files in rails app"
  task :clean => :environment do
    file_paths = Dir.glob("#{Rails.root}/**/*").reject do |file_path|
      File.directory?(file_path) || file_path.gsub("#{Rails.root}/", "").start_with?("node_modules", "tmp", "public", "log", "app/assets/builds", "app/assets/fonts", "app/assets/images", "vendor") || file_path.end_with?(".lock", ".lockb")
    end

    puts "Cleaning files..."

    file_paths.each.with_index do |file_path, index|
      puts "#{index + 1}/#{file_paths.size} - #{file_path}"
      ImmosquareCleaner.clean(file_path)
    end
  end
end
