//
//  ToggleTableViewCell.swift
//  loopr-ios
//
//  Created by Matthew Cox on 2/11/18.
//  Copyright © 2018 Loopring. All rights reserved.
//

import UIKit

class ToggleTableViewCell: UITableViewCell {

    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var settingToggle: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func switchChanged(_ sender: Any) {
    
    }
    
}
