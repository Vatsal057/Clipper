#!/usr/bin/env ruby
# Generates Clipper.xcodeproj from the Clipper/ source directory.
# Run from repo root: ruby scripts/gen_project.rb
require 'xcodeproj'
require 'fileutils'

# ---- EDIT ME ---------------------------------------------------------------
APP_NAME = 'Clipper'
EXT_NAME = nil          # no widget extension
DEPLOY   = '14.0'
PREFIX   = ENV['BUNDLE_PREFIX'] || 'com.vatsal.clipper'
# ----------------------------------------------------------------------------

ROOT      = Dir.pwd
proj_path = File.join(ROOT, "#{APP_NAME}.xcodeproj")
FileUtils.rm_rf(proj_path)
project = Xcodeproj::Project.new(proj_path)

BUILD_VERSION = '3'  # static — changing this resets TCC Accessibility grant

def common(bc, extra = {})
  s = bc.build_settings
  s['MACOSX_DEPLOYMENT_TARGET'] = DEPLOY
  s['SWIFT_VERSION']            = '5.0'
  s['CODE_SIGN_STYLE']          = 'Automatic'
  s['MARKETING_VERSION']        = '2.0'
  s['CURRENT_PROJECT_VERSION']  = BUILD_VERSION
  s['GENERATE_INFOPLIST_FILE']  = 'NO'    # hand-crafted Info.plist
  s['INFOPLIST_FILE']           = 'Clipper/Info.plist'
  s['ENABLE_HARDENED_RUNTIME']  = 'NO'    # CGEventTap needs no hardened runtime
  s['CODE_SIGN_ENTITLEMENTS']   = 'Clipper/Clipper.entitlements'
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  extra.each { |k, v| s[k] = v }
end

app = project.new_target(:application, APP_NAME, :osx, DEPLOY)
app.build_configurations.each do |bc|
  common(bc,
    'PRODUCT_BUNDLE_IDENTIFIER'               => PREFIX,
    'INFOPLIST_KEY_NSHumanReadableCopyright'  => '',
    'INFOPLIST_KEY_LSApplicationCategoryType' => 'public.app-category.utilities')
end

app_group = project.new_group(APP_NAME, APP_NAME)

# Add asset catalog
assets_ref = app_group.new_reference('Assets.xcassets')
app.add_resources([assets_ref])

# Collect all .swift files recursively under Clipper/
swift_files = Dir.glob("#{APP_NAME}/**/*.swift").sort
swift_files.each do |f|
  rel   = f.sub("#{APP_NAME}/", '')
  parts = rel.split('/')
  grp   = app_group
  parts[0..-2].each do |part|
    grp = grp[part] || grp.new_group(part, part)
  end
  ref = grp.new_reference(File.basename(f))
  app.source_build_phase.add_file_reference(ref)
end

project.save
puts "Generated #{proj_path}"
