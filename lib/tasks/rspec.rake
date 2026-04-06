# frozen_string_literal: true

# RSpec related tasks
namespace :spec do
  desc "Run all specs with coverage report"
  task :coverage do
    ENV["COVERAGE"] = "true"
    Rake::Task["spec"].invoke
    puts "\nCoverage report generated at: coverage/index.html"
  end

  desc "Run specs and open coverage report"
  task :coverage_open do
    ENV["COVERAGE"] = "true"
    Rake::Task["spec"].invoke

    if RUBY_PLATFORM =~ /darwin/
      system "open coverage/index.html"
    elsif RUBY_PLATFORM =~ /linux/
      system "xdg-open coverage/index.html"
    else
      puts "\nCoverage report generated at: coverage/index.html"
    end
  end

  desc "Run only model specs"
  task :models do
    system "bundle exec rspec spec/models"
  end

  desc "Run only request specs"
  task :requests do
    system "bundle exec rspec spec/requests"
  end

  desc "Run only system specs"
  task :system do
    system "bundle exec rspec spec/system"
  end

  desc "Run only failed specs from last run"
  task :failed do
    system "bundle exec rspec --only-failures"
  end

  desc "Run specs with documentation format"
  task :doc do
    system "bundle exec rspec --format documentation"
  end

  desc "Profile slow specs"
  task :profile do
    system "bundle exec rspec --profile 20"
  end
end
