//
//  ShopLogo.swift
//  kvitai
//
//  Created by Domantas Bernatavicius on 2022-07-03.
//

import SwiftUI

struct ShopLogo: View {
    let type: String

    var body: some View {
        return Image("logo-\(type)").resizable().scaledToFit()
            .frame(width: 50, height: 50)
    }
}

struct ShopLogo_Previews: PreviewProvider {
    static var previews: some View {
        ShopLogo(type: "IKI")
    }
}
