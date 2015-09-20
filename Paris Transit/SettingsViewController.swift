//
//  SettingsViewController.swift
//  Paris Transit
//
//  Created by Adam McNight on 18/09/2015.
//  Copyright © 2015 Vanadium Applications. All rights reserved.
//

import UIKit
import Accounts
import Social

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.followVanadium()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Follow Twitter Stuff
    
    func followVanadium() {
        let account = ACAccountStore()
        let twitterAccountType = account.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
    
        account.requestAccessToAccountsWithType(twitterAccountType, options: nil) { (success, error) -> Void in
            if success {
                let allAcounts = account.accountsWithAccountType(twitterAccountType)
                
                if allAcounts.count > 0 {
                    let twitterAccount = allAcounts.last as! ACAccount // On devrait plutôt afficher tous les comptes et laisser le user choisir
                    
                    // ALREADY FOLLOWING VERIFICATION
                    
                    let paramsVerif = [  "screen_name" : "AdaMcNight" ]
                    let requestURLVerif = NSURL(string: "https://api.twitter.com/1.1/users/show.json")
                    
                    let getRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: requestURLVerif, parameters: paramsVerif)
                    
                    getRequest.account = twitterAccount
                    
                    getRequest.performRequestWithHandler({ (data, response, error) -> Void in
                        if let error = error {
                            print("Error : \(error.localizedDescription)")
                        } else {
                            do {
                                let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! [String : AnyObject]
                                let following = json["following"] as! Bool
                                
                                if following {
                                    print("Vous me suivez déjà. Merci !")
                                }
                                else {
                                    let params = [  "screen_name" : "AdaMcNight",
                                        "follow" : true]
                                    let requestURL = NSURL(string: "https://api.twitter.com/1.1/friendships/create.json")
                                    
                                    let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter,
                                        requestMethod: .POST, URL: requestURL, parameters: params)
                                    
                                    postRequest.account = twitterAccount
                                    
                                    postRequest.performRequestWithHandler({ (data, response, error) -> Void in
                                        if let error = error {
                                            print("Error : \(error.localizedDescription)")
                                        } else {
                                            if response.statusCode == 200 {
                                                print("Merci !")
                                            } else {
                                                print("Oops !")
                                            }
                                        }
                                    })
                                }
                            } catch let error as NSError {
                                print("Error parsing : \(error.localizedDescription)")
                            }
                        }
                    })
                }
                else {
                    print("Aucun compte Twitter !")
                }
            } else {
                print("Error : \(error.localizedDescription)")
            }
        }
    }


    // MARK: - Table view data source

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
