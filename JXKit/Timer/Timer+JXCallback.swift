//
//  Timer+JXCallback.swift
//  DQGuess
//
//  Created by jiaxin on 2018/5/3.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

import Foundation

extension Timer {
    class func jx_scheduledTimer(timeInterval ti: TimeInterval, repeats yesOrNo: Bool, callback: @escaping (Timer)->()) -> Timer {
        let target = JXTimerWeakTarget()
        return target.scheduledTimer(timeInterval: ti, repeats: yesOrNo, callback: callback)
    }
}


class JXTimerWeakTarget: NSObject {
    var targetCallback: ((Timer)->())?
    weak var targetTimer: Timer?

    func scheduledTimer(timeInterval ti: TimeInterval, repeats yesOrNo: Bool, callback: @escaping (Timer)->()) -> Timer {
        targetCallback = callback
        let timer = Timer.scheduledTimer(timeInterval: ti, target: self, selector: #selector(timerCallback), userInfo: nil, repeats: yesOrNo)
        targetTimer = timer
        return timer
    }

    @objc func timerCallback() {
        DispatchQueue.main.async {
            if self.targetTimer != nil {
                self.targetCallback?(self.targetTimer!)
            }
        }
    }
}

