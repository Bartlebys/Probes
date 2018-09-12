//
//  FileListViewController.swift
//  Probes
//
//  Created by Benoit Pereira da silva on 31/07/2018.
//  Copyright © 2018 Bartlebys. All rights reserved.
//

import Cocoa
import BartlebysCore


enum ScanError:Error {
    case urlIsNotAFolder(url:URL)
}

class FileListViewController: NSViewController {


    @IBOutlet weak var tableView: NSTableView!{
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
        }
    }

    var delegate: DetailDelegate?

    public fileprivate (set) var baseFolderURL: URL?

    public fileprivate (set) var traces: [Trace] = [Trace]()

    override func viewDidAppear() {
        super.viewDidAppear()
        self._selectFolder()
    }

    fileprivate func _selectFolder(){
        if let window: NSWindow = self.view.window{
            let openPanel = NSOpenPanel()
            openPanel.message = NSLocalizedString("Select the probes source folder", comment: "Select the probes source folder")
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.canCreateDirectories = false
            openPanel.beginSheetModal(for: window) { (result) in
                syncOnMain {
                    if result == NSApplication.ModalResponse.OK  {
                        self.baseFolderURL = openPanel.url
                        self._scanFolder()
                    
                    } else {
                        // Nothing
                    }
                }
            }
        }
    }


    fileprivate func _scanFolder(){

        guard let probesFolderURL = self.baseFolderURL else { return }

        self.traces.removeAll()

        do{
            let probesFolderContent:[URL] = try FileManager.default.contentsOfDirectory(at: probesFolderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            for folderURL in probesFolderContent{
                let subFolders:[URL] = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                for subFolderURL in subFolders{
                    do{
                        let traces:[Trace] = try self._tracesFrom(folderURL: subFolderURL)
                        if traces.count > 0 {
                            self.traces.append(contentsOf: traces)
                        }
                    }catch{
                        Logger.log("\(error)")
                    }
                }

            }
        }catch{
            Logger.log("\(error)")
        }

        self.traces.sort { (rTrace, lTrace) -> Bool in
            return rTrace.classifier.hashValue > lTrace.classifier.hashValue || rTrace.callCounter < lTrace.callCounter
        }

        // reload
        self.tableView.reloadData()
    }


    fileprivate func _tracesFrom(folderURL:URL) throws -> [Trace]{
        var isDirectory:ObjCBool = true
        FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory)
        if isDirectory.boolValue == true {
            let id = folderURL.lastPathComponent
            let probesFiles:[URL] = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter({$0.isFileURL})
            var traces: [Trace] = [Trace]()
            for probeFileURL in probesFiles{
                do {
                    var trace: Trace = try Trace.from(probeFileURL)
                    trace.classifier = id
                    traces.append(trace)
                }catch{
                    Logger.log(error)
                }
            }
            return traces
        }else{
            throw ScanError.urlIsNotAFolder(url: folderURL)
        }
     }

}


extension FileListViewController: NSTableViewDataSource{ 

    public func numberOfRows(in tableView: NSTableView) -> Int{
        return self.traces.count
    }


    /* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView). Note that NSTableCellView does not actually display the objectValue, and its value is to be used for bindings. See NSTableCellView.h for more information.
     */
    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?{
        let trace = self.traces[row]
        guard let column = tableColumn else {
            return nil
        }
        if column.identifier == NSUserInterfaceItemIdentifier("classifier"){
            return trace.classifier
        }else if column.identifier == NSUserInterfaceItemIdentifier("counter"){
            return trace.callCounter.paddedString(6)

        }else if column.identifier == NSUserInterfaceItemIdentifier("status"){
            return trace.httpStatus
        }else if column.identifier == NSUserInterfaceItemIdentifier("sizeOfResponse"){
            return ByteCountFormatter.string(fromByteCount: Int64(trace.sizeOfResponse), countStyle:.file)
        }else if column.identifier == NSUserInterfaceItemIdentifier("url"){
            return trace.request.url?.absoluteString ?? ""
        }else if column.identifier == NSUserInterfaceItemIdentifier("method"){
            return trace.request.httpMethod
        }
        return nil
    }
}

extension FileListViewController: NSTableViewDelegate{


    public func tableViewSelectionDidChange(_ notification: Notification){
        if let tableView = notification.object as? NSTableView {
            let row = tableView.selectedRow
            if  row != -1 {
                let selectedTrace = self.traces[row]
                self.delegate?.displayDetail(of: selectedTrace)
            }
        }
    }
}
