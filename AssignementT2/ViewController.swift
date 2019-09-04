//
//  ViewController.swift
//  AssignementT2
//
//  Created by apple on 02/09/19.
//  Copyright © 2019 Swiftter. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController {
    
    var footerView:FooterReusableView?
    var searches = PhotoResults()
    let networkManager = NetworkManager()
    var itemsPerRow: CGFloat = 2
    let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    var paging : Paging?
    var loadMore: Bool = false
    var selectedCellFrame: CGRect?
    var selectedIndexPath: IndexPath?
    let footerViewReuseIdentifier = "RefreshFooterView"
    var activityIndicator : UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        collectionView?.register(UINib(nibName: "FooterReusableView", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footerViewReuseIdentifier)
        
        self.fetchImageFromApi(pageNo: 2)

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func photoForIndexPath(indexPath: IndexPath) -> PhotoModel {
        return searches.searchResults[(indexPath as NSIndexPath).row]
    }
    
}



// MARK: UICollectionViewDataSource
extension ViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searches.searchResults.count
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCollectionViewCell.identifier, for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.isUserInteractionEnabled = true
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension ViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        self.perform(#selector(postNotification), with: nil, afterDelay: 0.1)
    }
    
    @objc func postNotification () {
        let flickrPhoto = photoForIndexPath(indexPath: selectedIndexPath!)
        NotificationCenter.default.post(name: NSNotification.Name("LoadImage"), object: flickrPhoto)
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastRowIndex = collectionView.numberOfItems(inSection: 0) - 1
        if indexPath.row == lastRowIndex && paging != nil {
            loadMorePhotos()
        }
        let flickrPhoto = photoForIndexPath(indexPath: indexPath)
        ImageDownloadManager.shared.downloadImage(flickrPhoto, indexPath: indexPath) { (image, url, indexPathh, error) in
            if let indexPathNew = indexPathh, indexPathNew == indexPath {
                DispatchQueue.main.async {
                    (cell as! PhotoCollectionViewCell).imageView.image = image
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if self.loadMore {return}
        let flickrPhoto = photoForIndexPath(indexPath: indexPath)
        ImageDownloadManager.shared.slowDownImageDownloadTaskfor(flickrPhoto)
    }
    
    private func loadMorePhotos() {

        if !loadMore && paging!.currentPage! < paging!.totalPages! {
            loadMore = true
            self.fetchImageFromApi(pageNo: paging!.currentPage! + 1)
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if self.loadMore {
            return CGSize.zero
        }
        return CGSize(width: collectionView.bounds.size.width, height: 55)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let aFooterView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerViewReuseIdentifier, for: indexPath) as! FooterReusableView
            self.footerView = aFooterView
            self.footerView?.backgroundColor = UIColor.clear
            return aFooterView
        } else {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerViewReuseIdentifier, for: indexPath)
            return headerView
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            self.footerView?.prepareInitialAnimation()
        }
    }
    override func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if elementKind == UICollectionView.elementKindSectionFooter {
            self.footerView?.stopAnimate()
        }
    }
    
    //compute the scroll value and play witht the threshold to get desired effect
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold   = 100.0 ;
        let contentOffset = scrollView.contentOffset.y;
        let contentHeight = scrollView.contentSize.height;
        let diffHeight = contentHeight - contentOffset;
        let frameHeight = scrollView.bounds.size.height;
        var triggerThreshold  = Float((diffHeight - frameHeight))/Float(threshold);
        triggerThreshold   =  min(triggerThreshold, 0.0)
        let pullRatio  = min(abs(triggerThreshold),1.0);
        self.footerView?.setTransform(inTransform: CGAffineTransform.identity, scaleFactor: CGFloat(pullRatio))
        if pullRatio >= 1 {
            self.footerView?.animateFinal()
        }
    }
    
    //compute the offset and call the load method
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let contentOffset = scrollView.contentOffset.y;
        let contentHeight = scrollView.contentSize.height;
        let diffHeight = contentHeight - contentOffset;
        let frameHeight = scrollView.bounds.size.height;
        let pullHeight  = abs(diffHeight - frameHeight);
        if pullHeight == 0.0
        {
            if (self.footerView?.isAnimating)! {
                self.footerView?.startAnimate()
            }
        }
    }
    
    
    
}

extension ViewController {
    
    func fetchImageFromApi (pageNo: Int) {
        networkManager.fetchImage(page: pageNo) { results, paging, error in
            
            if let paging = paging, paging.currentPage == 1 {
                ImageDownloadManager.shared.cancelAll()
                self.searches.searchResults.removeAll()
                self.collectionView?.reloadData()
            }
            
            if let error = error {
                print("Error====\(error)")
                self.showErrorAlert(with: "Please check Internet connection")
                return
            }
            
            if let results = results {
                self.searches.searchResults.append(contentsOf: results.searchResults)

                self.paging = paging
                self.collectionView?.reloadData()
            }
            self.loadMore = false
        }
    }
    
    private func showErrorAlert(with message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    
}


