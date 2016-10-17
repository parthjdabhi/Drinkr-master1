//
//  BarNearbyMeCollectionViewCell.swift
//  Drinkr
//
//  Created by iParth on 10/17/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

class BarNearbyMeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imgBar: UIImageView!
    @IBOutlet weak var lblBarTitle: UILabel!
    @IBOutlet weak var lblDealDetail: UILabel!
    @IBOutlet weak var lblTime: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    
    static let identifier = "BarNearbyMeCollectionViewCell"
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //        self.image.layer.cornerRadius = max(self.image.frame.size.width, self.image.frame.size.height) / 2
        //        self.image.layer.borderWidth = 10
        //        self.image.layer.borderColor = UIColor(red: 110.0/255.0, green: 80.0/255.0, blue: 140.0/255.0, alpha: 1.0).CGColor
    }
    
}
