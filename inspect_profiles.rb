require 'find'

profiles_dir = File.expand_path('~/Library/MobileDevice/Provisioning Profiles')
unless Dir.exist?(profiles_dir)
  puts "No profiles dir"
  exit
end

Find.find(profiles_dir) do |path|
  if path =~ /\.mobileprovision$/
    content = File.read(path, encoding: 'binary')
    plist_start = content.index(/<\?xml/)
    plist_end = content.index(/<\/plist>/)
    if plist_start && plist_end
      plist_data = content[plist_start...(plist_end + 8)]
      name = plist_data.match(/<key>Name<\/key>\s*<string>(.*?)<\/string>/)&.captures&.first
      app_id = plist_data.match(/<key>application-identifier<\/key>\s*<string>(.*?)<\/string>/)&.captures&.first
      get_task_allow = plist_data.match(/<key>get-task-allow<\/key>\s*<(true|false)\/>/)&.captures&.first
      
      bundle_id = app_id.sub(/^[^\.]+\./, '') if app_id
      is_dist = get_task_allow == 'false'
      puts "Found profile: #{bundle_id} - #{name} (Distribution: #{is_dist})"
    end
  end
end
puts "Done inspecting profiles."
