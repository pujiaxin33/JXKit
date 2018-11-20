//
//  JXBufferManager.swift
//  DQGuess
//
//  Created by jiaxin on 2018/11/16.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import Foundation


/// 缓冲指定时间再去执行任务
/// 中间可以取消之前的缓冲执行的任务
/// 适用场景：某个任务创建和销毁比较消耗性能、内存。但是需要点击某个item才需要创建，点击另一个item需要销毁。但是用户有可能会频繁点击，导致频繁创建销毁，可能会出现未知问题。所以，该场景可以通过缓冲销毁任务来避免。
/// 从A切换到B，缓冲销毁A的某个任务。快速从B切换到A，取消之前A的销毁任务，中间就没有真正执行销毁任务，当前的A任务还处于执行状态。
class JXBufferManager {
    static let shared = JXBufferManager()
    private var taskDict = [String: JXBufferTask]()

    func registTask(taskID: String, buffterTime: Double, taskBlock: @escaping ()->()) {
        let task = JXBufferTask()
        task.taskID = taskID
        task.taskBlock = taskBlock
        task.bufferTime = buffterTime
        task.didStartedCallback = {[weak self] in
            self?.taskDict.removeValue(forKey: taskID)
        }
        task.start()
        taskDict[taskID] = task
    }

    func unregistTask(taskID: String) -> JXBufferTask? {
        let task = taskDict[taskID]
        if task != nil {
            task?.stop()
            self.taskDict.removeValue(forKey: taskID)
        }
        return task
    }
}

class JXBufferTask {
    var taskID: String?
    var taskBlock: (()->())?
    var bufferTime: Double?
    var timer: Timer?
    var didStartedCallback: (()->())?

    func start()  {
        timer = Timer.jx_scheduledTimer(timeInterval: bufferTime!, repeats: false, callback: {[weak self] (timer) in
            self?.taskBlock?()
            self?.didStartedCallback?()
        })
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        taskBlock = nil
        didStartedCallback = nil
    }
}
