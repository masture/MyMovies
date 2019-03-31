//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginViaWebsiteButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    
    @IBAction func loginTapped(_ sender: UIButton) {
        
        TMDBClient.requestToken(completionHandler: handleRequestTokenResponse(success:error:))
    }
    
    private func handleRequestTokenResponse(success: Bool, error: Error?) {
        if success {
            print("Access Token: \(TMDBClient.Auth.requestToken)")
            
            DispatchQueue.main.async {
                let user = LoginRequest(userName: self.emailTextField.text!, password: self.passwordTextField.text!, requestToken: TMDBClient.Auth.requestToken)
                
                TMDBClient.requestLogin(for: user, completionHandler: self.handleRequestLogin(success:error:))
            }
        }
    }
    
    private func handleRequestLogin(success: Bool, error: Error?) {
        if success {
            TMDBClient.requestSessionId(completionHandler: handleRequestSessionResponse(success:error:))
        }
    }
    
    
    func handleRequestSessionResponse(success: Bool, error: Error?) {
        if success {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "completeLogin", sender: nil)
            }
        }
    }
    
    @IBAction func loginViaWebsiteTapped() {

        TMDBClient.requestToken { (success, error) in
            if success {
                DispatchQueue.main.async {
                    UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil)
                }
                
            }
        }
    }
    
}
