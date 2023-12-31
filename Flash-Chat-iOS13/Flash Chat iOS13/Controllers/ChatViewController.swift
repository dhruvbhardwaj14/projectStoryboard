//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase
class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    let db=Firestore.firestore()
    var messages:[Message]=[]
    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.delegate=self
        tableView.dataSource=self
        title=K.appName
        navigationItem.hidesBackButton=true
        
        //registering cell to view
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        //pull up the current data from firestore
        loadMessages()
    }
    func loadMessages(){
        
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { querySnapshot, error in
            self.messages=[]
            if let e=error{
                print("There was an issue retrieving data from firestore \(e)")
            }
            else{
                if let snapshotDocument=querySnapshot?.documents{
                    for doc in snapshotDocument{
                        let data=doc.data()
                        if let messageSender=data[K.FStore.senderField] as? String,let messageBody=data[K.FStore.bodyField] as? String{
                            let newMessage=Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                //to reach very end of our messages array
                                let indexPath=IndexPath(row: self.messages.count-1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top , animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody=messageTextfield.text,let messageSender=Auth.auth().currentUser?.email{
            db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.senderField:messageSender,K.FStore.bodyField:messageBody,K.FStore.dateField:Date().timeIntervalSince1970]){(error) in
                if let e=error{
                    print("There was an issues saving data for firestore, \(e)")
                }
                else{
                    print("successfully saved data")
                    DispatchQueue.main.async {
                        self.messageTextfield.text=""
                    }
                    
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
    do {
      try Auth.auth().signOut()
        navigationController?.popToRootViewController(animated: true)//return to root home screen
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
    }
      
    }
    
}
extension ChatViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message=messages[indexPath.row]
        let cell=tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier,for: indexPath) as! MessageCell
        cell.label.text=message.body
        //this is a message from current user
        if message.sender == Auth.auth().currentUser?.email{
            cell.leftImageView.isHidden=true
            cell.rightImageVIew.isHidden = false
            cell.messageBubble.backgroundColor=UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor=UIColor(named: K.BrandColors.purple)
        }
        //this message is from another sender
        else{
            cell.leftImageView.isHidden=false
            cell.rightImageVIew.isHidden = true
            cell.messageBubble.backgroundColor=UIColor(named: K.BrandColors.purple)
            cell.label.textColor=UIColor(named: K.BrandColors.lightPurple)
        }
        
        return cell
    }
}
//extension ChatViewController:UITableViewDelegate{
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print(indexPath.row)
//    }
//}
