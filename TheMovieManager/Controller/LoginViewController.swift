//
//  LoginViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
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
        setLoggingIn(true)
        TMDBClient.requestToken(completionHandler: handleRequestTokenResponse(success:error:))
    }
    
    private func handleRequestTokenResponse(success: Bool, error: Error?) {
        if success {
            print("Access Token: \(TMDBClient.Auth.requestToken)")
            
            let user = LoginRequest(userName: self.emailTextField.text!, password: self.passwordTextField.text!, requestToken: TMDBClient.Auth.requestToken)
            
            TMDBClient.requestLogin(for: user, completionHandler: self.handleRequestLogin(success:error:))
        } else {
            showLoginFailure(message: error?.localizedDescription ?? "")
            setLoggingIn(false)
        }
    }
    
    private func handleRequestLogin(success: Bool, error: Error?) {
        if success {
            TMDBClient.requestSessionId(completionHandler: handleRequestSessionResponse(success:error:))
        } else {
            showLoginFailure(message: error?.localizedDescription ?? "")
            setLoggingIn(false)
        }
    }
    
    
    func handleRequestSessionResponse(success: Bool, error: Error?) {
        setLoggingIn(false)
        if success {
            self.performSegue(withIdentifier: "completeLogin", sender: nil)
        } else {
            showLoginFailure(message: error?.localizedDescription ?? "")
            setLoggingIn(false)
        }
    }
    
    @IBAction func loginViaWebsiteTapped() {
        setLoggingIn(true)
        TMDBClient.requestToken { (success, error) in
            if success {
                DispatchQueue.main.async {
                    UIApplication.shared.open(TMDBClient.Endpoints.webAuth.url, options: [:], completionHandler: nil)
                }
                
            }
        }
    }
    
    private func setLoggingIn(_ loggingIn: Bool) {
        if loggingIn {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        loginButton.isEnabled = !loggingIn
        loginViaWebsiteButton.isEnabled = !loggingIn
        emailTextField.isEnabled = !loggingIn
        passwordTextField.isEnabled = !loggingIn
    }
    
    
    func showLoginFailure(message: String) {
        let alertVC = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
}
