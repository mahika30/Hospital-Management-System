//
//  QRCodeView.swift
//  iHMS
//
//  Created by Hargun Singh on 07/01/26.
//


import SwiftUI

struct QRCodeView: View {
    let data: String

    var body: some View {
        Image(uiImage: QRCodeGenerator.generate(from: data))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }
}
