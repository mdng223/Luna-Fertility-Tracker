//
//  AppDelegate.swift
//  Luna
//
//  Created by Logan Blevins on 9/13/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?
	
	// MARK: App Delegate callbacks
	//
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey:Any]? ) -> Bool
    {
		Fabric.with( [ Crashlytics.self ] )
		FIRApp.configure()
		
		signInUser()
		
		return true
	}
	
	func applicationWillTerminate(_ application: UIApplication )
	{
		FirebaseAuthenticationService.RemoveAuthChangeListener( self.authChangeHandle )
	}
	
	// MARK: Implmentation Details
	//
	
	fileprivate func signInUser()
	{
		// Check if we have a pre-existing user.
		// 
		// If so, do nothing.
		// If not, present login VC -> present onboarding.
		//
		self.authChangeHandle = FirebaseAuthenticationService.AuthChangeListener()
		{
			[weak self] user in
			guard let strongSelf = self else { return }
			
			if user == nil
			{
				let loginViewController = LoginViewController.storyboardInstance()!
				loginViewController.delegate = strongSelf.MainViewController()
				let mainVC = strongSelf.MainViewController()
				mainVC.present( loginViewController, animated: true, completion: nil )
			}
		}
	}
		
	fileprivate func MainViewController() -> MainViewController
	{
		return ( window!.rootViewController as! MainViewController )
	}
	
	fileprivate var authChangeHandle: FIRAuthStateDidChangeListenerHandle!
}
