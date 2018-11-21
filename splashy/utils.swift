//
//  utils.swift
//  splashy
//
//  Created by David Thompson on 21/11/2018.
//  Copyright © 2018 the beardy developer. All rights reserved.
//

import Foundation

public extension CGFloat {
    public static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }

    public static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat.random() * (max - min) + min
    }
}
