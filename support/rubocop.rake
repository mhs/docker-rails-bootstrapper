# frozen_string_literal: true

require "rubocop/rake_task"

RuboCop::RakeTask.new(:rubocop) do |t|
  t.requires << "rubocop-rails"
  t.options = ["--parallel"]
end
