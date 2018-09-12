//
//  RootViewController.swift
//  iOS-Depth-Sampler
//
//  Created by Shuichi Tsutsumi on 2018/09/11.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit

class RootViewController: UITableViewController {

    private let dataSource = SampleDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.samples.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? RootViewCell else {fatalError()}
        
        let sample = dataSource.samples[(indexPath as NSIndexPath).row]
        cell.showSample(sample)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sample = dataSource.samples[(indexPath as NSIndexPath).row]
        
        navigationController?.pushViewController(sample.controller(), animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
