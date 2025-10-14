//
//  ContentProvider.swift
//  tromsoTopshelf
//
//  Created by Brad Park on 5/19/20.
//  Copyright © 2020 Brad Park. All rights reserved.
//

import TVServices

class ContentProvider: TVTopShelfContentProvider {

	override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
	    // Fetch content and call completionHandler
	    completionHandler(nil);
	}

}

