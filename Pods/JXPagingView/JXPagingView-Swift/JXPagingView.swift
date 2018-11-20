//
//  JXPagingView.swift
//  JXPagingView
//
//  Created by jiaxin on 2018/5/22.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

import UIKit

@objc public protocol JXPagingViewListViewDelegate: NSObjectProtocol {

    /// 返回listView
    ///
    /// - Returns: UIView
    func listView() -> UIView

    /// 返回listView内部持有的UIScrollView或UITableView或UICollectionView
    /// 主要用于mainTableView已经显示了header，listView的contentOffset需要重置时，内部需要访问到外部传入进来的listView内的scrollView
    ///
    /// - Returns: listView内部持有的UIScrollView或UITableView或UICollectionView
    func listScrollView() -> UIScrollView


    /// 当listView内部持有的UIScrollView或UITableView或UICollectionView的代理方法`scrollViewDidScroll`回调时，需要调用该代理方法传入的callback
    ///
    /// - Parameter callback: `scrollViewDidScroll`回调时调用的callback
    func listViewDidScrollCallback(callback: @escaping (UIScrollView)->())

    /// 将要重置listScrollView的contentOffset
    @objc optional func listScrollViewWillResetContentOffset()
}

@objc public protocol JXPagingViewDelegate: NSObjectProtocol {


    /// tableHeaderView的高度，因为内部需要比对判断，只能是整型数
    ///
    /// - Parameter pagingView: JXPagingViewView
    /// - Returns: height
    func tableHeaderViewHeight(in pagingView: JXPagingView) -> Int


    /// 返回tableHeaderView
    ///
    /// - Parameter pagingView: JXPagingViewView
    /// - Returns: view
    func tableHeaderView(in pagingView: JXPagingView) -> UIView


    /// 返回悬浮HeaderView的高度，因为内部需要比对判断，只能是整型数
    ///
    /// - Parameter pagingView: JXPagingViewView
    /// - Returns: height
    func heightForPinSectionHeader(in pagingView: JXPagingView) -> Int


    /// 返回悬浮HeaderView。我用的是自己封装的JXCategoryView（Github:https://github.com/pujiaxin33/JXCategoryView），你也可以选择其他的三方库或者自己写
    ///
    /// - Parameter pagingView: JXPagingViewView
    /// - Returns: view
    func viewForPinSectionHeader(in pagingView: JXPagingView) -> UIView

    /// 返回listViews，只要遵循JXPagingViewListViewDelegate即可，无论你返回的是UIView还是UIViewController都可以。
    ///
    /// - Parameter pagingView: JXPagingViewView
    /// - Returns: listViews
    func listViews(in pagingView: JXPagingView) -> [JXPagingViewListViewDelegate]

    /// mainTableView的滚动回调，用于实现头图跟随缩放
    ///
    /// - Parameter scrollView: JXPagingViewMainTableView
    @objc optional func mainTableViewDidScroll(_ scrollView: UIScrollView)
}

open class JXPagingView: UIView {
    public unowned let delegate: JXPagingViewDelegate
    open var mainTableView: JXPagingMainTableView!
    open var listContainerView: JXPagingListContainerView!
    var currentScrollingListView: UIScrollView?
    var currentListView: JXPagingViewListViewDelegate?

    public init(delegate: JXPagingViewDelegate) {
        self.delegate = delegate
        super.init(frame: CGRect.zero)

        initializeViews()
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func initializeViews(){
        mainTableView = JXPagingMainTableView(frame: CGRect.zero, style: .plain)
        mainTableView.showsVerticalScrollIndicator = false
        mainTableView.showsHorizontalScrollIndicator = false
        mainTableView.separatorStyle = .none
        mainTableView.dataSource = self
        mainTableView.delegate = self
        mainTableView.tableHeaderView = self.delegate.tableHeaderView(in: self)
        mainTableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "cell")
        addSubview(mainTableView)

        if #available(iOS 11.0, *) {
            mainTableView.contentInsetAdjustmentBehavior = .never
        } 

        listContainerView = JXPagingListContainerView(delegate: self)
        listContainerView.mainTableView = mainTableView

        configListViewDidScrollCallback()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        mainTableView.frame = self.bounds
    }


    open func reloadData() {
        self.currentListView = nil
        self.currentScrollingListView = nil
        configListViewDidScrollCallback()
        self.mainTableView.tableHeaderView = self.delegate.tableHeaderView(in: self)
        self.mainTableView.reloadData()
        self.listContainerView.reloadData()
    }

    open func preferredProcessListViewDidScroll(scrollView: UIScrollView) {
        if (self.mainTableView.contentOffset.y < getTableHeaderViewHeight()) {
            //mainTableView的header还没有消失，让listScrollView一直为0
            self.currentListView?.listScrollViewWillResetContentOffset?()
            currentScrollingListView!.contentOffset = CGPoint.zero;
            currentScrollingListView!.showsVerticalScrollIndicator = false;
        } else {
            //mainTableView的header刚好消失，固定mainTableView的位置，显示listScrollView的滚动条
            self.mainTableView.contentOffset = CGPoint(x: 0, y: self.delegate.tableHeaderViewHeight(in: self));
            currentScrollingListView!.showsVerticalScrollIndicator = true;
        }
    }

    open func preferredProcessMainTableViewDidScroll(_ scrollView: UIScrollView) {
        if (self.currentScrollingListView != nil && self.currentScrollingListView!.contentOffset.y > 0) {
            //mainTableView的header已经滚动不见，开始滚动某一个listView，那么固定mainTableView的contentOffset，让其不动
            self.mainTableView.contentOffset = CGPoint(x: 0, y: self.delegate.tableHeaderViewHeight(in: self))
        }

        if (mainTableView.contentOffset.y < getTableHeaderViewHeight()) {
            //mainTableView已经显示了header，listView的contentOffset需要重置
            for listView in self.delegate.listViews(in: self) {
                listView.listScrollViewWillResetContentOffset?()
                listView.listScrollView().contentOffset = CGPoint.zero
            }
        }

        if scrollView.contentOffset.y > getTableHeaderViewHeight() && self.currentScrollingListView?.contentOffset.y == 0 {
            //当往上滚动mainTableView的headerView时，滚动到底时，修复listView往上小幅度滚动
            self.mainTableView.contentOffset = CGPoint(x: 0, y: self.delegate.tableHeaderViewHeight(in: self))
        }
    }

    //MARK: - Private

    func configListViewDidScrollCallback() {
        let listViews = self.delegate.listViews(in: self)
        for listView in listViews {
            listView.listViewDidScrollCallback {[weak self, weak listView] (scrollView) in
                self?.currentListView = listView
                self?.listViewDidScroll(scrollView: scrollView)
            }
        }
    }

    func getTableHeaderViewHeight() -> CGFloat {
        return CGFloat(self.delegate.tableHeaderViewHeight(in: self))
    }

    func getPinSectionHeaderHeight() -> CGFloat {
        return CGFloat(self.delegate.heightForPinSectionHeader(in: self))
    }

    /// 外部传入的listView，当其内部的scrollView滚动时，需要调用该方法
    func listViewDidScroll(scrollView: UIScrollView) {
        self.currentScrollingListView = scrollView

        preferredProcessListViewDidScroll(scrollView: scrollView)
    }
}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension JXPagingView: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bounds.height - getPinSectionHeaderHeight()
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        listContainerView.frame = cell.contentView.bounds
        cell.contentView.addSubview(listContainerView)
        listContainerView.setNeedsLayout()
        listContainerView.layoutIfNeeded()
        return cell
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return getPinSectionHeaderHeight()
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.delegate.viewForPinSectionHeader(in: self)
    }

    //加上footer之后，下滑滚动就变得丝般顺滑了
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: CGRect.zero)
        footerView.backgroundColor = UIColor.clear
        return footerView
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate.mainTableViewDidScroll?(scrollView)
        //用户正在上下滚动的时候，就不允许左右滚动
        if scrollView.isTracking {
            self.listContainerView.collectionView.isScrollEnabled = false
        }

        preferredProcessMainTableViewDidScroll(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.listContainerView.collectionView.isScrollEnabled = true
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.listContainerView.collectionView.isScrollEnabled = true
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.listContainerView.collectionView.isScrollEnabled = true
    }
}

extension JXPagingView: JXPagingListContainerViewDelegate {
    public func numberOfRows(in listContainerView: JXPagingListContainerView) -> Int {
        let listViews = self.delegate.listViews(in: self)
        return listViews.count
    }
    public func listContainerView(_ listContainerView: JXPagingListContainerView, viewForListInRow row: Int) -> UIView {
        let listViews = self.delegate.listViews(in: self)
        return listViews[row].listView()
    }

    public func listContainerView(_ listContainerView: JXPagingListContainerView, willDisplayCellAt row: Int) {let listViews = self.delegate.listViews(in: self)
        self.currentScrollingListView = listViews[row].listScrollView()
    }
}



