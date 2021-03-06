//
//  DetailViewController.swift
//  FlickrViewer
//
//  Created by Kirill Shteffen on 04/09/2018.
//  Copyright © 2018 BlackBricks. All rights reserved.
//

import UIKit
import SDWebImage


class DetailViewController: UIViewController {
    
    var isTopViewHidden = false 
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var photos: [Photo] = []
    var selectedIndex: IndexPath? = nil
    
    override var prefersStatusBarHidden: Bool {
      return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate() 
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let indexToScroll = selectedIndex else {
            return
        }
        collectionView.scrollToItem(at: indexToScroll, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: false)
    }
    
}

extension DetailViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DetailCollectionViewCell", for: indexPath) as? DetailCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.detailDelegate = self
        cell.detailViewContentSet(flickrPhoto: photos[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}

extension DetailViewController: DetailViewCellDelegate {
    //MARK - Detail View closing function
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}
