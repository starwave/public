import MultipeerConnectivity

/* samsung galaxy quickshare with near device for file transfer in mac os x swift code without viewcontroller */

class QuickShareManager: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var advertiser: MCNearbyServiceAdvertiser!
    var browser: MCNearbyServiceBrowser!

    override init() {
        super.init()
        // Initialize the peer ID and session
        peerID = MCPeerID(displayName: Host.current().localizedName ?? "Unknown Device")
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self

        // Set up the advertiser
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "quick-share")
        advertiser.delegate = self

        // Set up the browser
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "quick-share")
        browser.delegate = self
    }

    // Function to start advertising
    func startAdvertising() {
        advertiser.startAdvertisingPeer()
    }

    // Function to start browsing
    func startBrowsing() {
        browser.startBrowsingForPeers()
    }

    // Function to send file
    func sendFile(url: URL) {
        if mcSession.connectedPeers.count > 0 {
            for peer in mcSession.connectedPeers {
                mcSession.sendResource(at: url, withName: url.lastPathComponent, toPeer: peer) { (error) in
                    if let error = error {
                        print("Error sending file: \(error.localizedDescription)")
                    } else {
                        print("File sent successfully")
                    }
                }
            }
        }
    }

    // MARK: - MCSessionDelegate Methods
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("\(peerID.displayName) connected")
        case .connecting:
            print("\(peerID.displayName) connecting")
        case .notConnected:
            print("\(peerID.displayName) not connected")
        @unknown default:
            fatalError()
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle received data
        print("Received data: \(data.count) bytes")
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Handle received stream
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Handle start receiving resource
        print("Started receiving resource: \(resourceName) from \(peerID.displayName)")
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Handle finish receiving resource
        if let error = error {
            print("Error receiving resource: \(error.localizedDescription)")
        } else {
            print("Finished receiving resource: \(resourceName)")
            // Move or process the received file as needed
            if let localURL = localURL {
                do {
                    let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    let destinationURL = documentsURL.appendingPathComponent(resourceName)
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    print("File saved to: \(destinationURL.path)")
                } catch {
                    print("Error saving file: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - MCNearbyServiceAdvertiserDelegate Methods
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error.localizedDescription)")
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }

    // MARK: - MCNearbyServiceBrowserDelegate Methods
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error.localizedDescription)")
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}
