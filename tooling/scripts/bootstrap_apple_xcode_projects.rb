#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "xcodeproj"

ROOT = Pathname(__dir__).join("../..").realpath

def ensure_file_reference(project, relative_path)
  existing = project.files.find { |file| file.path == relative_path.to_s }
  return existing if existing

  project.main_group.new_file(relative_path.to_s)
end

def assign_target_xcconfigs(project, target, config_dir)
  target.build_configurations.each do |config|
    file_name = case config.name
                when "Debug" then "Debug.xcconfig"
                when "Release" then "Release.xcconfig"
                else "Base.xcconfig"
                end
    ref = ensure_file_reference(project, config_dir.join(file_name))
    config.base_configuration_reference = ref
  end
end

def assign_project_xcconfigs(project, config_dir)
  project.build_configurations.each do |config|
    ref = ensure_file_reference(project, config_dir.join("Base.xcconfig"))
    config.base_configuration_reference = ref
  end
end

def configure_common_swift_settings(target)
  target.build_configurations.each do |config|
    config.build_settings["SWIFT_VERSION"] = "6.0"
    config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
    config.build_settings["INFOPLIST_KEY_CFBundleDisplayName"] = "$(PRODUCT_NAME)"
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] ||= "com.altis.bootstrap.$(PRODUCT_NAME:rfc1034identifier)"
  end
end

def add_sources(project, target, relative_paths)
  refs = relative_paths.map { |path| ensure_file_reference(project, Pathname(path)) }
  target.add_file_references(refs)
end

def ensure_group(project, name)
  existing = project.main_group.groups.find { |group| group.display_name == name || group.path == name }
  return existing if existing

  project.main_group.new_group(name)
end

def add_docs_references(project, relative_paths)
  docs_group = ensure_group(project, "Docs")
  relative_paths.each do |path|
    next if docs_group.files.any? { |file| file.path == path }

    docs_group.new_file(path)
  end
end

def add_unit_test_dependency(test_target, app_target)
  test_target.add_dependency(app_target)
  test_target.build_configurations.each do |config|
    config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
    config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/#{app_target.product_name}.app/Contents/MacOS/#{app_target.product_name}" if app_target.platform_name == :osx
  end
end

def create_macos_project
  project_dir = ROOT.join("apple/macos")
  project_path = project_dir.join("AltisMacOS.xcodeproj")
  project_path.rmtree if project_path.exist?

  project = Xcodeproj::Project.new(project_path.to_s)
  app_target = project.new_target(:application, "AltisMacOS", :osx, "15.0")
  test_target = project.new_target(:unit_test_bundle, "AltisMacOSTests", :osx, "15.0")

  configure_common_swift_settings(app_target)
  configure_common_swift_settings(test_target)
  add_sources(project, app_target, [
    "App/AltisMacOSApp.swift",
    "App/RootView.swift"
  ])
  add_sources(project, test_target, [
    "Tests/AltisMacOSTests.swift"
  ])
  add_docs_references(project, [
    "MACOS_MVP_TASK_BREAKDOWN.md"
  ])
  add_unit_test_dependency(test_target, app_target)
  assign_project_xcconfigs(project, Pathname("Config"))
  assign_target_xcconfigs(project, app_target, Pathname("Config"))
  assign_target_xcconfigs(project, test_target, Pathname("Config"))

  project.save
end

def create_ios_project
  project_dir = ROOT.join("apple/ios")
  project_path = project_dir.join("AltisIOS.xcodeproj")
  project_path.rmtree if project_path.exist?

  project = Xcodeproj::Project.new(project_path.to_s)
  app_target = project.new_target(:application, "AltisIOS", :ios, "17.0")
  test_target = project.new_target(:unit_test_bundle, "AltisIOSTests", :ios, "17.0")

  configure_common_swift_settings(app_target)
  configure_common_swift_settings(test_target)
  add_sources(project, app_target, [
    "App/AltisIOSApp.swift",
    "App/RootView.swift"
  ])
  add_sources(project, test_target, [
    "Tests/AltisIOSTests.swift"
  ])
  test_target.add_dependency(app_target)
  assign_project_xcconfigs(project, Pathname("Config"))
  assign_target_xcconfigs(project, app_target, Pathname("Config"))
  assign_target_xcconfigs(project, test_target, Pathname("Config"))

  project.save
end

# Parse --platform flag. Accepted values: macos, ios, all (default: macos)
# During Phase 0 the default is macOS-only. Pass --platform all to generate both.
platform_arg = ARGV.select { |a| a.start_with?("--platform=") }.last
platform = platform_arg ? platform_arg.split("=", 2).last : "macos"

generated = []

if %w[macos all].include?(platform)
  create_macos_project
  generated << "apple/macos/AltisMacOS.xcodeproj"
end

if %w[ios all].include?(platform)
  create_ios_project
  generated << "apple/ios/AltisIOS.xcodeproj"
end

if generated.empty?
  warn "Unknown --platform value '#{platform}'. Use: macos, ios, all"
  exit 1
end

puts "Generated:"
generated.each { |p| puts "- #{p}" }
