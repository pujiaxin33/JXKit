//
//  JXSwiftDefine.swift
//  JXKit
//
//  Created by jiaxin on 2018/11/20.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import Foundation
import UIKit

let JXAppDelegateWindow = UIApplication.shared.delegate!.window!
let ScreenWidth = UIScreen.main.bounds.size.width
let ScreenHeight = UIScreen.main.bounds.size.height
let JXLineWidth: CGFloat = 1.0/UIScreen.main.scale

func ImageWithName(_ name: String) -> UIImage? {
    return UIImage.init(named: name)
}
func ColorWithRGBA(_ red: CGFloat,_  green: CGFloat,_ blue: CGFloat, _ alpha: CGFloat) -> UIColor {
    return UIColor.init(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
}
func ColorWithHex(_ hex: Int, _ alpha: CGFloat) -> UIColor {
    return ColorWithRGBA((CGFloat((hex & 0xFF0000) >> 16)), (CGFloat((hex & 0xFF00) >> 8)), (CGFloat(hex & 0xFF)), alpha)
}

func JXAdjustsScrollViewInsetsToNO(scrollView: UIScrollView, vc: UIViewController) {
    if #available(iOS 11.0, *) {
        scrollView.contentInsetAdjustmentBehavior = .never
    } else {
        vc.automaticallyAdjustsScrollViewInsets = false
    }
}
func JXErrorStringFormatter(error: Error?) -> String {
    var string = "服务器开小差了，待会儿再试吧"
    if let errorString = error?.localizedDescription {
        string = errorString
    }
    return string
}

//MARK: - MVVM
protocol JXViewModelType {
    associatedtype Input
    associatedtype Output

    var input: Input { get set }
    var output: Output { get set }

    init(input : Input)
}


