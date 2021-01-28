# frozen_string_literal: true

require "capybara/rspec"

# Shush puma on start
Capybara.server = :puma, { Silent: true }

module SystemTestHelpers
  def host_location_of(filepath)
    filepath.sub(Regexp.escape("#{Rails.root}/"), "")
  end

  def save_screenshot_and_report
    puts "saved screenshot to #{host_location_of(save_screenshot)}"
  end

  def save_page_and_report
    puts "saved page to #{host_location_of(save_page)}"
  end
end

RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system

  # Save page & screenshot so errors can be viewed outside container if :screenshots is specified
  config.after(:each, type: :system, screenshot: true) do |scenario|
    if scenario.exception
      puts "An exception occurred"
      save_screenshot_and_report
      save_page_and_report
    end
  end

  # TRICKY: Chrome does not like to be run as root, but that's the only user in our Rails container. By sending
  # --no-sandbox we disable a bunch of protections we shouldn't need in tests and circumvent this problem
  default_chrome_args = %w[
    --disable-dev-shm-usage
    --start-maximized
    --no-sandbox
  ]

  # Driver registration
  Capybara.register_driver :chrome_desktop do |app|
    options = Selenium::WebDriver::Chrome::Options.new(args: default_chrome_args + ["--window-size=1280,720"])
    options.headless!
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.register_driver :chrome_iphone do |app|
    options = Selenium::WebDriver::Chrome::Options.new(args: default_chrome_args)
    options.add_emulation(device_name: "iPhone X")
    options.headless!
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  config.before(:each, type: :system) do
    driven_by :chrome_desktop
  end

  config.before(:each, type: :system, mobile: true) do
    driven_by :chrome_iphone
  end
end
