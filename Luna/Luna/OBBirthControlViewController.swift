//
//  OBBirthControlViewController.swift
//  Luna
//
//  Created by Erika Wilcox on 11/8/16.
//  Copyright © 2016 Logan Blevins. All rights reserved.
//

import UIKit

class OBBirthControlViewController: UIViewController, UIPickerViewDataSource,UIPickerViewDelegate
{
	var itemIndex = 0
	
    static func storyboardInstance() -> OBBirthControlViewController?
    {
        let storyboard = UIStoryboard( name: String( describing: self ), bundle: nil )
        return storyboard.instantiateInitialViewController() as? OBBirthControlViewController
    }
        
    override func viewDidLoad()
	{
        super.viewDidLoad()

        birthControlPicker.delegate = self
        birthControlPicker.dataSource = self
        setUIPickerView()
    }

    func numberOfComponents( in pickerView: UIPickerView ) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return uiPickerValues.count
    }
	
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int ) -> NSAttributedString?
	{
		let attributes = [NSForegroundColorAttributeName: UIColor.white]
		let text = NSAttributedString( string: uiPickerValues[row], attributes: attributes )
		return text
	}
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int )
    {
        selectedValue = uiPickerValues[row]
    }
    
    func maybeUploadData()
    {
        if !selectedValue.isEmpty
        {
            birthControlViewModel.onAddDataAttempt( data: selectedValue )
        }
    }

    fileprivate func setUIPickerView()
    {
        uiPickerValues = birthControlViewModel.getPickerValues()
        
        if ( uiPickerValues.count > 0 )
        {
            selectedValue = uiPickerValues[0]
        }
    }
	
    @IBOutlet weak var birthControlPicker: UIPickerView!
    
    fileprivate var uiPickerValues: [String] = []
    fileprivate var selectedValue: String = ""
	
    fileprivate let birthControlViewModel = BirthControlViewModel( dbService: FirebaseDBService() )
}
