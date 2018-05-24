//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Jimit Shah on 5/23/18.
//  Copyright © 2018 Jimit Shah. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
  DispatchQueue.main.async {
    updates()
  }
}
