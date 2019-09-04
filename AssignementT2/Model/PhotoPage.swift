//
//  PhotoPage.swift
//  AssignementT2
//
//  Created by apple on 02/09/19.
//  Copyright © 2019 Swiftter. All rights reserved.
//

import Foundation

public class Paging {
    
    public var totalPages: Int?
    public var numberOfElements: Int32?
    public var currentSize: Int = 20
    public var currentPage: Int?
    
    init(totalPages: Int, elements: Int32, currentPage: Int) {
        self.totalPages = totalPages
        self.numberOfElements = elements
        self.currentPage = currentPage
    }
}
