//
//  SearchViewController.swift
//  FlickrViewer
//
//  Created by Kirill Shteffen on 06/07/2018.
//  Copyright © 2018 BlackBricks. All rights reserved.
//

import UIKit
import Alamofire
import PullToRefresh

class SearchViewController: UIViewController, UISearchBarDelegate {
    
    var photos: [Photo] = []
    private var request: DataRequest? = nil
    private var currentPage = 0
    private var currentSearch = ""
    private var refresherState: State? = nil
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 4
            layout.minimumInteritemSpacing = 0
        }
        //MARK-refresher
        let refresher = PullToRefresh()
        refresherState = refresher.state
        print("REFRESHERSTATE IS \(refresher.state)")
        collectionView.addPullToRefresh(refresher){
            self.getExploreFlickrPhotos(pageNumber: 1){
                print("POPULAR PHOTOS REFRESHED")
                self.sizeToArrayCollecting(photos: self.photos)
                self.collectionView.reloadData()
                self.activityIndicator.stopAnimating()
                print("REFRESHERSTATE IS \(refresher.state)")
                self.collectionView.endAllRefreshing()
            }
        }
        
        //Mark-first request
        getExploreFlickrPhotos(pageNumber: 1) {
            self.sizeToArrayCollecting(photos: self.photos)
            print("POPULAR PHOTOS ADDED")
            print("REQUEST STATUS NOW IS \(String(describing: self.request?.progress.isFinished))")
            self.collectionView.reloadData()
            self.activityIndicator.stopAnimating()
            self.currentPage = 1
        }
        activityIndicator.startAnimating()
    }
    
    private func getExploreFlickrPhotos(pageNumber: Int, completion: @escaping () -> ()) {
        justifiedSizes = []
        let requestUrl = FlickrURL()
        let pageNumber: Int = pageNumber
        let flickrUrlString = requestUrl.baseUrl +
            requestUrl.popularPhotosQuery +
            requestUrl.apiKey +
            requestUrl.extras +
            requestUrl.recentPhotosPerPage +
            requestUrl.page +
            String(pageNumber) +
            requestUrl.format
        print("\(flickrUrlString)")
        
        request = Alamofire.request(flickrUrlString).responseJSON { [weak self] response in
            guard response.result.isSuccess else {
                print("REQUEST ERROR\(String(describing: response.result.error))")
                return
            }
            guard let photoData = response.data else {
                return
            }
            
            let flickrPhotos = try? JSONDecoder().decode(FlickrPhotos.self, from: photoData)
            guard let photoArray = flickrPhotos?.photos.photo else {
                let error = UIAlertController(
                    title: "Error", message: "Explore photos not set", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("FETCHING ERROR")
                })
                error.addAction(ok)
                self?.present(error, animated: true, completion: nil)
                self?.collectionView.endAllRefreshing()
                self?.activityIndicator.stopAnimating()
                return
            }
            if  self?.refresherState?.description == "Initial"  {
                self?.photos = photoArray
            }else{
                self?.photos += photoArray}
            completion()
        }
    }
    
    private func flickrPhotosSearch(searchText: String, completion: @escaping () -> ()) {
        justifiedSizes = []
        currentPage = 1
        currentSearch = searchText
        print("Current SEARCH is \(currentSearch)")
        let requestUrl = FlickrURL()
        let pageNumber: Int = 1
        let flickrUrlString = requestUrl.baseUrl +
            requestUrl.searchQuery +
            requestUrl.apiKey +
            requestUrl.searchTags +
            ("\(searchText)") +
            requestUrl.extras +
            requestUrl.sort +
            requestUrl.photosPerPage +
            requestUrl.page +
            String(pageNumber) +
            requestUrl.format
        print("\(flickrUrlString)")
        request =  Alamofire.request(flickrUrlString).responseJSON { [weak self] response in
            guard let photoData = response.data else {
                return
            }
            
            let flickrPhotos = try? JSONDecoder().decode(FlickrPhotos.self, from: photoData)
            guard let photoArray = flickrPhotos?.photos.photo else {
                let error = UIAlertController(
                    title: "Error", message: "Search query unsuccessfull!", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    print("FETCHING ERROR")
                })
                error.addAction(ok)
                self?.present(error, animated: true, completion: nil)
                self?.activityIndicator.stopAnimating()
                return
            }
            self?.photos = photoArray
            completion()
        }
    }
    
    var justifiedSizes: [CGSize] = []
    
    func sizeToArrayCollecting(photos: [Photo]) {
        var unfetchedSizes: [CGSize] = []
        for item in photos {
            guard let width = Int(item.width_m) else {
                return
            }
            guard let height = Int(item.height_m) else {
                return
            }
            let size = CGSize(width: width, height: height)
            unfetchedSizes.append(size)
        }
        justifiedSizes = unfetchedSizes.lay_justify(for: 370, preferredHeight: 180)
    }
}
// MARK: UICollectionViewDataSource
extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard justifiedSizes.count != 0 else {
            return CGSize(width: 0.5, height: 0.5)
        }
        return justifiedSizes[indexPath.item]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as? ImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.setupWithPhoto(flickrPhoto: photos[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let desVC = mainStoryboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
        desVC?.photos = self.photos
        desVC?.selectedIndex = indexPath
        
        self.navigationController?.pushViewController(desVC!, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (request?.progress.isFinished)! {
            if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height {
                self.activityIndicator.startAnimating()
                getExploreFlickrPhotos(pageNumber: currentPage + 1) {
                    self.sizeToArrayCollecting(photos: self.photos)
                    self.currentPage += 1
                    print("One more page loaded. CURRENT PAGE IS \(self.currentPage)")
                    self.collectionView.reloadData()
                    self.activityIndicator.stopAnimating()
                }
            }
        }
    }
}
