//
//  SplitViewController.swift
//  Probes
//
//  Created by Benoit Pereira da silva on 31/07/2018.
//  Copyright © 2018 Bartlebys. All rights reserved.
//

import Cocoa
import BartlebysCore

class SplitViewController: NSSplitViewController {

    @IBOutlet weak var detailItem: NSSplitViewItem!

    @IBOutlet weak var listItem: NSSplitViewItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let detail : DetailViewController = self.detailItem.viewController as? DetailViewController{
            if let list: FileListViewController = self.listItem.viewController as? FileListViewController{
                list.delegate = detail
            }
        }
    }

}
