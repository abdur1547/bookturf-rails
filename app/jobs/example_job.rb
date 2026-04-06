# frozen_string_literal: true

class ExampleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    puts "Example job is running with arguments: #{args.inspect}"
  end
end
