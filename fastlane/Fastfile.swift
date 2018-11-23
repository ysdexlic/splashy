// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
	func betaLane() {
	desc("Push a new beta build to TestFlight")
		buildApp(workspace: "splashy.xcworkspace", scheme: "splashy")
		uploadToTestflight(username: "david.arthur.thompson@gmail.com")
	}
}
