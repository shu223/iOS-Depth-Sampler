platform :ios, '11.0'

target 'iOS-Depth-Sampler' do
  use_frameworks!

  pod 'Vivid'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
	    target.build_configurations.each do |config|
	        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
	        if target.name == 'Vivid'
              config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
	        end
	    end
    end
end
