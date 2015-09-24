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
import PTKit
import SVProgressHUD

class SettingsViewController: UITableViewController {

    @IBOutlet weak var followTwitterCell: UITableViewCell!
    @IBOutlet weak var displayNonStoppingTrainsSwitch: UISwitch!
    
    @IBOutlet weak var currentRadiusLabel: UILabel!
    @IBOutlet weak var currentRadiusStepper: UIStepper!
    
    @IBOutlet weak var loveBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.prepareUserInterface()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - User Interface
    
    func prepareUserInterface() {
        // Settings
        self.displayNonStoppingTrainsSwitch.on = PTPreferencesManager.sharedManager.displayNonStoppingTrains()
        let currentRadius = PTPreferencesManager.sharedManager.radiusStopPlaces()
        self.currentRadiusStepper.value = currentRadius
        self.currentRadiusLabel.text = PTLocationManager.sharedManager.distanceFormatter.stringFromDistance(currentRadius)
        
        // Social
        if PTPreferencesManager.sharedManager.twitterAccessAsked() {
            if PTPreferencesManager.sharedManager.doesUserFollowUs() {
                self.loveBarButtonItem.enabled = true
                self.followTwitterCell.textLabel!.text = "Merci. Voir mes tweets !"
            } else {
                self.loveBarButtonItem.enabled = false
                self.followTwitterCell.textLabel!.text = "Snif... Voir mes tweets quand même !"
            }
        }
        else {
            self.loveBarButtonItem.enabled = false
        }
    }
    
    // MARK: - Actions
    
    @IBAction func displayNonStoppingTrainsValueChanged(sender: UISwitch) {
        PTPreferencesManager.sharedManager.setDisplayNonStoppingTrains(sender.on)
    }
    
    @IBAction func radiusStopPlacesSteppedValueChanged(sender: UIStepper) {
        let currentRadius = sender.value
        PTPreferencesManager.sharedManager.setRadiusStopPlaces(currentRadius)
        self.currentRadiusLabel.text = PTLocationManager.sharedManager.distanceFormatter.stringFromDistance(currentRadius)
    }
    
    // MARK: - Follow Twitter Stuff
    
    func twitterVerifications() {
        let account = ACAccountStore()
        let twitterAccountType = account.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
    
        account.requestAccessToAccountsWithType(twitterAccountType, options: nil) { (success, error) -> Void in
            PTPreferencesManager.sharedManager.setTwitterAccessAsked(true)
            
            if success {
                let allAcounts = account.accountsWithAccountType(twitterAccountType)
                
                if allAcounts.count > 0 {
                    let twitterAccount = allAcounts.last as! ACAccount // On devrait plutôt afficher tous les comptes et laisser le user choisir
                    
                    self.doYouFollowVanadiumVerification(twitterAccount, completionHandler: { (follow) -> Void in
                        PTPreferencesManager.sharedManager.setUserFollowUs(follow)
                        
                        if follow {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.loveBarButtonItem.enabled = true
                                self.followTwitterCell.textLabel!.text = "Merci de me suivre sur Twitter !"
                            }
                        }
                        else {
                            self.followVanadium(twitterAccount)
                        }
                    })
                }
                else {
                    print("Aucun compte Twitter !")
                }
            }
            else {
                print("Access denied !")
            }
        }
    }
    
    func doYouFollowVanadiumVerification(account: ACAccount, completionHandler: (follow: Bool) -> Void) {
        let paramsVerif = [  "screen_name" : "AdaMcNight" ]
        let requestURLVerif = NSURL(string: "https://api.twitter.com/1.1/users/show.json")
        
        let getRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: requestURLVerif, parameters: paramsVerif)
        
        getRequest.account = account
        
        getRequest.performRequestWithHandler { (data, response, error) -> Void in
            if let error = error {
                print("Error : \(error.localizedDescription)")
                
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(follow: false)
                }
            }
            else {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! [String : AnyObject]
                    let following = json["following"] as! Bool
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(follow: following)
                    }
                } catch let error as NSError {
                    print("Error parsing : \(error.localizedDescription)")
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        completionHandler(follow: false)
                    }
                }
            }
        }
    }
    
    func followVanadium(account: ACAccount) {
        let params = [  "screen_name" : "AdaMcNight",
            "follow" : true]
        let requestURL = NSURL(string: "https://api.twitter.com/1.1/friendships/create.json")
        
        let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter,
            requestMethod: .POST, URL: requestURL, parameters: params)
        
        postRequest.account = account
        
        postRequest.performRequestWithHandler({ (data, response, error) -> Void in
            if let error = error
            {
                self.showErrorWithStatus("Oops... Erreur : \(error.localizedDescription)")
            }
            else
            {
                if response.statusCode == 200
                {
                    self.showSuccessWithStatus("Merci !")
                }
                else
                {
                    self.showErrorWithStatus("Oops... Erreur ! (Code \(response.statusCode))")
                }
            }
        })
    }
    
    private func showSuccessWithStatus(status: String) {
        PTPreferencesManager.sharedManager.setUserFollowUs(true)
        
        dispatch_async(dispatch_get_main_queue()) {
            SVProgressHUD.showSuccessWithStatus(status)
            self.loveBarButtonItem.enabled = true
        }
    }

    private func showErrorWithStatus(status: String) {
        dispatch_async(dispatch_get_main_queue()) {
            SVProgressHUD.showErrorWithStatus(status)
        }
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 0
        {
            if PTPreferencesManager.sharedManager.twitterAccessAsked()
            {
                UIApplication.sharedApplication().openURL(NSURL(string: "https://twitter.com/adamcnight")!)
            }
            else
            {
                self.twitterVerifications()
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
