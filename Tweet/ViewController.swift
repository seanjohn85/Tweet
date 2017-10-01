//
//  ViewController.swift
//  Tweet
//
//  Created by JOHN KENNY on 18/09/2017.
//  Copyright © 2017 JOHN KENNY. All rights reserved.
//

import Cocoa
import OAuthSwift
import SwiftyJSON
import Kingfisher

class ViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    //array of image links
    var imageURLs : [String] = []
    
    var tweetUrl : [String] = []
    @IBOutlet var collection: NSCollectionView!
    
    
    @IBOutlet var btn: NSButtonCell!
    
    @IBAction func signin(_ sender: Any) {
        if btn.title == "Log In"{
            logIn()
        }else{
            logOut()
        }
        
        
    }
    
    // create an instance and retain it
    let oauthswift = OAuth1Swift(
        consumerKey:    "ELCHpSlr1QFlK6V36hAKQduHQ",
        consumerSecret: "hxPdJE73JkI3fLMG5TitLNo8Lm44mLkQafjVXWrQl7BSePA9pI",
        requestTokenUrl: "https://api.twitter.com/oauth/request_token",
        authorizeUrl:    "https://api.twitter.com/oauth/authorize",
        accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 500, height: 500)
        layout.sectionInset = EdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        layout.minimumLineSpacing = 15.0
        layout.minimumInteritemSpacing = 15.0
        collection.collectionViewLayout = layout
        
        collection.delegate = self
        collection.dataSource = self
        //checks if the user is logged in
        checkUserTokens()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    //function to log user into twitter
    func logIn(){
        // authorize
        let handle = oauthswift.authorize(
            withCallbackURL: URL(string: "Tweet://home")!,
            success: { credential, response, parameters in
                ///stroess the log in tokesn in user defaults
                UserDefaults.standard.set(credential.oauthToken, forKey: "oauthToken")
                UserDefaults.standard.set(credential.oauthTokenSecret, forKey: "oauthTokenSecret")
                UserDefaults.standard.synchronize()
                
                //print(parameters["user_id"])
                // Do your request
                
                self.getTweets()
                self.btn.title = "Log Out"
        },
            failure: { error in
                print(error.localizedDescription)
        }
        )
    }
    //log out function
    func logOut(){
        //changes button title
        btn.title = "Log In"
        //removed the users oauth tokens
        UserDefaults.standard.removeObject(forKey: "oauthToken")
        UserDefaults.standard.removeObject(forKey: "oauthTokenSecret")
        UserDefaults.standard.synchronize()
        //removed images when user logs out
        imageURLs = []
        tweetUrl = []
        collection.reloadData()
    }
    
    //function to check tokens
    func checkUserTokens() {
        if let oauthToken = UserDefaults.standard.string(forKey: "oauthToken"){
            if let oauthTokenSecret = UserDefaults.standard.string(forKey: "oauthTokenSecret"){
                oauthswift.client.credential.oauthToken = oauthToken
                oauthswift.client.credential.oauthTokenSecret = oauthTokenSecret
                getTweets()
                self.btn.title = "Log Out"
            }
        }
    }
    
    
    
    //collection view functions
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        print("clicked")
        collection.deselectAll(nil)
        if let index = indexPaths.first{
            let url = URL(string : tweetUrl[index.item])
            //open web apge in browser
            NSWorkspace.shared().open(url!)
        }
        
        
    }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collection.makeItem(withIdentifier: "TweetItem", for: indexPath)
        //takes each image location from the images array
        let url = URL(string: imageURLs[indexPath.item])
        item.imageView?.kf.setImage(with: url)
        return item
    }
    
    //gets the users timeline of tweets and extracts the images from the users timeline
    func getTweets(){
        //get timeline of tweets
        let x = oauthswift.client.get("https://api.twitter.com/1.1/statuses/home_timeline.json",
                                      //gets all data
            parameters: ["tweet_mode" : "exended", "count" : 200],
            success: { response in
                let dataString = response.string
                print(dataString)
                let json = JSON(data: response.data)
                
                //loop throught the json and extract any images from the timeline
                for (tweet, tweetJson):(String, JSON) in json {
                    //Do something you want
                    //print(tweetJson["entities"]["media"])
                    var reTweeeted = false
                    
                    for (_, mediaJson) :(String, JSON) in tweetJson["retweeted_status"]["extended_entities"]["media"]{
                        print(mediaJson["media_url_https"])
                        reTweeeted = true
                        //apend image to image array
                        if let imageUrl = mediaJson["media_url_https"].string{
                            self.imageURLs.append(imageUrl)
                        }
                        if let tUrl = mediaJson["expanded_url"].string{
                            self.tweetUrl.append(tUrl)
                            
                        }
                    }
                    if !reTweeeted {
                        for (_, mediaJson) :(String, JSON) in tweetJson["extended_entities"]["media"]{
                            print(mediaJson["media_url_https"])
                            //apend image to image array
                            if let imageUrl = mediaJson["media_url_https"].string{
                                self.imageURLs.append(imageUrl)
                            }
                            if let tUrl = mediaJson["expanded_url"].string{
                                self.tweetUrl.append(tUrl)
                                
                            }
                        }
                    }
                    
                    
                }
                self.collection.reloadData()
        },
            failure: { error in
                print(error)
        }
        )
    }
    
    
}

