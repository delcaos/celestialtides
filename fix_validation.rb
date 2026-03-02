require 'xcodeproj'

project = Xcodeproj::Project.open('CelestialTides.xcodeproj')
app_target = project.targets.find { |t| t.name == 'CelestialTides' }

app_target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
  config.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
end

# Also add the exact expected keys for UISupportedInterfaceOrientations~ipad
project.save
puts 'Fixed Info.plist validation errors for App Store upload'
