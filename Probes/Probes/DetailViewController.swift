//
//  DetailViewController.swift
//  Probes
//
//  Created by Benoit Pereira da silva on 31/07/2018.
//  Copyright © 2018 Bartlebys. All rights reserved.
//

import Cocoa
import BartlebysCore

protocol DetailDelegate{

    func displayDetail(of trace: Trace)

}

class DetailViewController: NSViewController, DetailDelegate {


    @IBOutlet var callTextView: NSTextView!

    @IBOutlet var responseTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func displayDetail(of trace: Trace){

        /// 1# Display the request

        do{
            let request: CodableURLRequest = trace.request
            let requestData: Data = try JSON.prettyEncoder.encode(request)
            if let jsonString: String = String(data: requestData, encoding: .utf8){
                let decodedBody: String = request.decodedBody ?? ""
                let trimed:String = decodedBody.trimmingCharacters(in: CharacterSet.whitespaces)
                self.callTextView.string = jsonString + (trimed != "" ? "\n--decoded httpBody:\n\(decodedBody)" : "")
            }else{
                self.callTextView.string = NSLocalizedString("String is invalid", comment: "String is invalid")
            }
        }catch{
            self.callTextView.string = NSLocalizedString("Request is not decodable", comment: "Request is not decodable")
        }

        /// 2# Display the response
        do{
            let responseData: Data = trace.response
            let httpResponse: HTTPResponse = try JSON.decoder.decode(HTTPResponse.self, from: responseData)
            let prettyContent: String = httpResponse.prettyJsonContent ?? NSLocalizedString("HTTPResponse's content data is not a valid JSON", comment: "HTTPResponse's content data is not a valid JSON")
            if let jsonString: String = String(data: responseData, encoding: .utf8){
                self.responseTextView.string = jsonString + "\n--JSON response.content:\n\(prettyContent)"
            }else{
                self.responseTextView.string = NSLocalizedString("String is invalid", comment: "String is invalid")
            }
        }catch{
            if let string = String(data: trace.response, encoding: .utf8){
                self.responseTextView.string = string
            }else{
                self.responseTextView.string = NSLocalizedString("HTTPResponse is not decodable", comment: "HTTPResponse is not decodable") + "\n\(error)"
            }
        }
    }


}
