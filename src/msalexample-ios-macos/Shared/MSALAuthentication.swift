import MSAL

class MSALAuthentication {
    // 'Application (client) ID' of app registration in Azure portal - this value is a GUID
    private static let kClientId = ""

    // 'Tenant ID' of your Azure AD instance - this value is a GUID
    private static let kTenantId = ""
    
    private static let kAuthority = try! MSALB2CAuthority(url: URL(string: "https://login.microsoftonline.com/\(kTenantId)")!)
    private static let kConfig = MSALPublicClientApplicationConfig(clientId: kClientId, redirectUri: nil, authority: kAuthority)

    // In order to take advantage of token caching, your MSAL client singleton must
    // have a lifecycle that at least matches the lifecycle of the user's session in
    // the app.
    private static let kApplication: MSALPublicClientApplication = try! MSALPublicClientApplication(configuration: kConfig)
    
    public static func signin(completion: @escaping (_ accessToken: String?) -> Void) {
        #if os(iOS)
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        // IMPORTANT: For this sample it is possible to use the root. Please consider disconvering the top one
        // or pass an specific ViewController if required.
        let webviewParameters = MSALWebviewParameters(authPresentationViewController: window!.rootViewController!)
        #else
        let webviewParameters = MSALWebviewParameters()
        #endif

        let interactiveParameters = MSALInteractiveTokenParameters(scopes: ["user.read"], webviewParameters: webviewParameters)

        // If access token acquisition needs to happen multiple times in
        // iOS or macOS, only call this after checking for a cached token via
        // a call to kApplication?.acquireTokenSilent(with: MSALSilentTokenParameters).
        kApplication.acquireToken(with: interactiveParameters, completionBlock: { (result, error) in
            guard let authResult = result, error == nil else {
                print(error!.localizedDescription)
                
                completion(nil)
                return
            }
            
            completion(authResult.accessToken)
        })
    }
    
    public static func signout(completion: @escaping () -> Void) {
        let msalParams = MSALAccountEnumerationParameters()
        msalParams.returnOnlySignedInAccounts = true
        
        kApplication.accountsFromDevice(for: msalParams, completionBlock: { (accounts, error) in
            guard let deviceAccounts = accounts, error == nil else {
                print(error!.localizedDescription)
                return
            }

            #if os(iOS)
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            // IMPORTANT: For this sample it is possible to use the root. Please consider disconvering the top one
            // or pass an specific ViewController if required.
            let webviewParameters = MSALWebviewParameters(authPresentationViewController: window!.rootViewController!)
            #else
            let webviewParameters = MSALWebviewParameters()
            #endif

            for account in deviceAccounts {
                kApplication.signout(with: account, signoutParameters: MSALSignoutParameters(webviewParameters: webviewParameters), completionBlock: { (success, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                })
            }
            
            completion()
        })
    }
}
