//
//  TromsoTests.swift
//  TromsoTests
//
//  Created by brad on jafaga on 11/9/24.
//  Copyright © 2024 Brad Park. All rights reserved.
//

import XCTest
@testable import Tromso

final class TromsoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFileSync() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let wpsi = WallpaperServiceInfo.getInstance()
        if (wpsi.getOfflineMode()) {
            let fileManager = FileSyncManager(serverBase: "BP Photo/1990", force: true)
            fileManager.syncFiles(fileSyncDoneCallback: {
                print("file sync is finished")
            }, onEvent: nil)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
