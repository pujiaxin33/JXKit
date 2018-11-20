platform:ios, '9.0'

post_install do |installer|
    myTargets = ['JXMarqueeView', 'JXBottomSheetView', 'JXPagingView/Paging']
    installer.pods_project.targets.each do |target|
        if myTargets.include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end

use_frameworks!
inhibit_all_warnings!

target 'JXKit' do
pod 'JXGradientKit', '0.0.3'
pod 'JXPopupView', '0.0.3'
pod 'JXPagingView/Paging', '0.1.7'
pod 'JXBottomSheetView', '0.0.3'
pod 'JXMarqueeView', '0.0.5'
pod 'JXCategoryView', '1.1.2'
pod 'JXMovableCellTableView', '0.0.2'
end
