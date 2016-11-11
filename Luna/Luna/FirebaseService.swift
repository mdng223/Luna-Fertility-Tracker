//
//  FirebaseService.swift
//  Luna
//
//  Created by Erika Wilcox on 9/23/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import Firebase

protocol ServiceAuthenticatable
{
	func signInUser( withToken token: String, completion: @escaping(_ userID: String?, _ error: Error? ) -> Void )
	func signOutUser() throws
}

protocol ServiceStorable
{
	// TODO: Fill in generic storage needs.
    func uploadUserImage( forUid uid: String, imageData: Data, imagePath: String, completion: @escaping(_ userID: String?, _ error: Error? ) -> Void)
    
    func addUserImageDownloadLink( forUid uid: String, downloadLink: String )

}

protocol ServiceDBManageable
{
	func createUserRecord( forUid uid: String, username: String )
    
    func getCurrentUser() -> FIRUser
    
    func saveUserRecord( forUid uid: String, key: String, data: AnyObject )
    
    func getUserOnBoardStatus( forUid uid: String, completion: @escaping(_ status: Bool?) -> Void)
    
    func setOnBoardStatus( forUid uid: String, status: Bool )
    
    func getUserRecord ( uid: String, completion: ((_ result:Dictionary<String, AnyObject>?) -> Void)! )
}

struct FirebaseAuthenticationService: ServiceAuthenticatable
{
	static func AuthChangeListener( completion: @escaping(_ user: FIRUser? ) -> Void ) -> FIRAuthStateDidChangeListenerHandle!
	{
		let handle = FIRAuth.auth()?.addStateDidChangeListener()
		{
			_, user in
			
			print( "Firebase auth state did change." )
			completion( user )
		}
		return handle!
	}
	
	static func RemoveAuthChangeListener(_ handle: FIRAuthStateDidChangeListenerHandle! )
	{
		FIRAuth.auth()?.removeStateDidChangeListener( handle )
	}
	
	func signInUser( withToken token: FirebaseToken, completion: @escaping(_ userID: String?, _ error: Error? ) -> Void )
	{
		print( "Attempting to sign in user." )
		
		FIRAuth.auth()?.signIn( withCustomToken: token )
		{
			userOrNil, errorOrNil in
			completion( userOrNil?.uid, errorOrNil )
		}
	}
	
	func signOutUser() throws
	{
		print( "Attempting to sign out user." )
		try FIRAuth.auth()?.signOut()
	}
}

struct FirebaseStorageService: ServiceStorable
{
    fileprivate static let FirebaseDB = FIRDatabase.database().reference()
    fileprivate static let FirebaseStorage = FIRStorage.storage().reference( forURL: Constants.FirebaseStrings.StorageURL )
    
    fileprivate var Users = FirebaseDB.child( Constants.FirebaseStrings.ChildUsers )
    fileprivate var StorageRef = FirebaseStorage
    
    func uploadUserImage( forUid uid: String, imageData: Data, imagePath: String, completion: @escaping(_ userID: String?, _ error: Error? ) -> Void)
    {
        print( "Attempting to upload user photo." )
        
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        
        let uploadTask = StorageRef.child( imagePath ).put(imageData, metadata: metadata)
        
        uploadTask.observe(.failure)
        {
            snapshot in
            
            guard let storageError = snapshot.error else { return }
            
            guard let errorCode = FIRStorageErrorCode(rawValue: storageError as! NSInteger) else { return }
            
            print ( "An error has occurred trying to upload photo: \(storageError)" )
            
            switch errorCode
            {
            case .objectNotFound:
                // File doesn't exist
                completion( uid , snapshot.error )
                break
                
            case .unauthorized:
                // User doesn't have permission to access file
                completion( uid , snapshot.error )
                break
                
            case .cancelled:
                // User canceled the upload
                completion( uid , snapshot.error )
                break
                
            case .unknown:
                // Unknown error occurred, inspect the server response
                completion( uid , snapshot.error )
                break
                
            default:
                completion( uid , snapshot.error )
                break
            }
        }
        
        
        uploadTask.observe(.success)
        {
            snapshot in
            
            print("Image upload a success")
            
            guard let downloadlink = snapshot.metadata?.downloadURL()?.absoluteString else { return }
            
            self.addUserImageDownloadLink( forUid: uid, downloadLink: downloadlink )
        }
    }
    
    
    func addUserImageDownloadLink( forUid uid: String, downloadLink: String )
    {
        Users.child( uid ).child(Constants.FirebaseStrings.DictionaryUserImageKey).setValue( downloadLink )
        print( "Add user image download url in DB for uid: \( uid ), downloadUrl: \( downloadLink )")
    }
    
}

struct FirebaseDBService: ServiceDBManageable
{
	fileprivate static let FirebaseDB = FIRDatabase.database().reference()
	
	fileprivate var Users = FirebaseDB.child( Constants.FirebaseStrings.ChildUsers )
//	fileprivate var Entry = FirebaseDB.child( Constants.FirebaseStrings.ChildEntry )
//	fileprivate var DailyEntries = FirebaseDB.child( Constants.FirebaseStrings.ChildDailyEntries )
	
	func createUserRecord( forUid uid: String, username: String )
	{
		//Users.child( uid ).setValue( [Constants.FirebaseStrings.DictionaryUsernameKey: username] )
        Users.child( uid ).child( Constants.FirebaseStrings.DictionaryUsernameKey ).setValue( username )
		print( "Created user record in DB for uid: \( uid ), username: \( username )" )

	}
    
    func setOnBoardStatus( forUid uid: String, status: Bool )
    {
        Users.child( uid ).child( Constants.FirebaseStrings.DictionaryOnBoardStatus ).setValue( status );
    }

    
    func getCurrentUser() -> FIRUser
    {
        return (FIRAuth.auth()?.currentUser)!
    }
    
    func saveUserRecord( forUid uid: String, key: String, data: AnyObject )
    {
        Users.child( uid ).child( key ).setValue( data )
    }
    
    func getUserOnBoardStatus( forUid uid: String, completion: @escaping(_ status: Bool?) -> Void)
    {
    
        Users.child( uid ).child( Constants.FirebaseStrings.DictionaryOnBoardStatus ).observeSingleEvent(of: .value, with:
        {
            snapshot in
            
            print( snapshot )

            if snapshot.value is NSNull
            {
                print("dude, snapshot was null")
                //self.setOnBoardStatus( forUid: uid, status: false )
                    
                completion ( false )
                    
            }
            else
            {
                print(snapshot.key)
                    
                //self.setOnBoardStatus( forUid: uid, status: (snapshot.value != nil) )
                    
                completion ( snapshot.value as! Bool? )
            }
            
            
        })
        
    }
    
    func getUserRecord ( uid: String, completion: ((_ result:Dictionary<String, AnyObject>?) -> Void)! )
    {
        Users.child( uid ).observeSingleEvent(of: .value, with:
        {
            snapshot in
            
            print ( "User record: \(snapshot.value)" )
            
            if snapshot.value is NSNull
            {
                print("The user has not data")

            }
            else
            {
                if let dict = snapshot.value as? Dictionary<String, AnyObject>
                {
                    completion( dict )
                }
            }
            
        })
    }
    
    
    
}
