require "parallel"
require "etc"

namespace :immosquare_cleaner do
  ##============================================================##
  ## Runs immosquare-cleaner across every file of a Rails app to
  ## format/lint in bulk, dispatching by extension:
  ## RuboCop (.rb), erb_lint + htmlbeautifier (.html.erb),
  ## ESLint (.js/.ts/.jsx/.tsx), ImmosquareYaml (locales/*.yml),
  ## shfmt (.sh), Prettier (everything else).
  ##
  ## Useful to normalize a codebase in one shot (onboarding,
  ## cleaner version upgrade, large refactor) rather than
  ## relying on the per-file Edit/Write hook.
  ##
  ## Skips generated/non-source folders (asset builds,
  ## node_modules, vendor, tmp, log, public, db, test, coverage)
  ## and binary/lock files (.lock, .png, .csv, etc.).
  ##
  ## Parallelized via threads (linters shell out, so the GVL is
  ## released). Override with: CLEANER_THREADS=N rake ...
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
      "vendor",
      "db"
    ]
    extensions_to_exclude = [
      ".lock",
      ".lockb",
      ".otf",
      ".ttf",
      ".png",
      ".jpg",
      ".jpeg",
      ".gif",
      ".svg",
      ".ico",
      ".webp",
      ".csv"
    ]

    file_paths = Dir.glob("#{Rails.root}/**/*").reject do |file_path|
      File.directory?(file_path) || file_path.gsub("#{Rails.root}/", "").start_with?(*paths_to_exclude) || file_path.end_with?(*extensions_to_exclude)
    end

    total   = file_paths.size
    mutex   = Mutex.new
    index   = 0
    threads = ENV["CLEANER_THREADS"]&.to_i || [Etc.nprocessors, 8].min
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    puts("Cleaning #{total} files with #{threads} threads...")

    Parallel.each(file_paths, :in_threads => threads) do |file_path|
      i = mutex.synchronize { index += 1 }
      puts("#{i}/#{total} - #{file_path}")
      ImmosquareCleaner.clean(file_path)
    end

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    mins    = (elapsed / 60).to_i
    secs    = (elapsed % 60).round(1)
    puts("Done in #{mins}m #{secs}s (#{total} files, #{threads} threads)")
  end
end
