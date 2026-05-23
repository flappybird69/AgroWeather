//
//  AgroWeatherWidgetBundle.swift
//  AgroWeatherWidget
//
//  Created by John on 23/5/26.
//

import WidgetKit
import SwiftUI

@main
struct AgroWeatherWidgetBundle: WidgetBundle {
    var body: some Widget {
        AgroWeatherWidget()
        AgroWeatherWidgetControl()
    }
}
