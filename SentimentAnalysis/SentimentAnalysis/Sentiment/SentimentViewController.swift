//
//  SentimentViewController.swift
//  SentimentAnalysis
//
//  Created by Thales Frigo on 01/12/18.
//  Copyright © 2018 Thales Frigo. All rights reserved.
//

import UIKit
import Moya
import Result

class SentimentViewController: UIViewController, ErrorDisplayer, Loadable {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tweetText: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var screenName: UILabel!
    @IBOutlet weak var createdAt: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    
    @IBOutlet weak var result: UILabel!
    
    var viewModel: SentimentViewModel!
    
    init(viewModel: SentimentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        tweetText.text = viewModel.tweet.text
        userName.text = viewModel.tweet.user.name
        screenName.text = "@\(viewModel.tweet.user.screenName)"
        createdAt.text = DateFormatter.twitterShortDateFormat.string(from: viewModel.tweet.createdAt)
        userImage.download(viewModel.tweet.user.image)
        
        viewModel.state.onUpdate = { [weak self] state in
            DispatchQueue.main.async {
                guard let vc = self else { return }
                vc.stopLoading()
                switch state {
                case .loading:
                    vc.title = "Processing"
                    vc.startLoading()
                case .load(let sentiment):
                    vc.title = "Done"
                    let emotion = sentiment.emotion
                    vc.result.text = emotion.emoji
                    vc.view.backgroundColor = emotion.color
                    vc.animateSentiment()
                case .error(let error):
                    vc.title = "Error"
                    vc.show(error) {
                        vc.viewModel.analyzeDocument()
                    }
                default:
                    return
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.analyzeDocument()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let color = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3).cgColor
        
        contentView.layer.shadowColor = color
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 50
        contentView.layer.shadowOpacity = 1
        contentView.backgroundColor = .white
    }
    
    func setupNavigationItem() {
        navigationItem.leftBarButtonItem =
            UIBarButtonItem(
                barButtonSystemItem: .stop,
                target: self,
                action: #selector(SentimentViewController.close)
        )
    }
    
    @objc func close(){
        self.dismiss(animated: true, completion: nil)
    }
}

extension SentimentViewController {
    
    private func animateSentiment() {
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 0
        fadeOut.toValue = 1
        fadeOut.duration = 1
        
        let expandScale = CABasicAnimation()
        expandScale.keyPath = "transform"
        expandScale.valueFunction = CAValueFunction(name: CAValueFunctionName.scale)
        expandScale.fromValue = [0, 0, 0]
        expandScale.toValue = [1, 1, 1]
        expandScale.duration = 1.0
        
        let rotation = CABasicAnimation()
        rotation.keyPath  = "transform.rotation.z"
        rotation.toValue  = CGFloat(360).degreesToRadians
        rotation.duration = 1.0
        
        let fadeAndScale = CAAnimationGroup()
        fadeAndScale.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.4, 0.8, 1.0)
        fadeAndScale.animations = [fadeOut, expandScale, rotation]
        fadeAndScale.duration = 1.0
        
        result.layer.add(fadeAndScale, forKey: nil)
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
