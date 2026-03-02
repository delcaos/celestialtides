require 'xcodeproj'
project = Xcodeproj::Project.open('CelestialTides.xcodeproj')

project.targets.each do |target|
  target.build_configurations.each do |config|
    if config.name == 'Release'
      config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
      config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    end
  end
end

project.save
puts 'Reverted project signing settings to Apple Development for Release'
