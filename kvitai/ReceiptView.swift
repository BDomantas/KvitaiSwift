//
//  ReceiptView.swift
//  kvitai
//
//  Created by Domantas Bernatavicius on 2022-07-03.
//

import SwiftUI

struct ReceiptView: View {
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var receipt: Receipt

    @State private var type: String
    @State private var description: String
    @State private var date: Date
    @State private var image: UIImage?
    @State private var shortSerial: String
    @State private var longSerial: String
    @State private var sum: String

    let types = ["IKI"]

    init(receipt: Receipt) {
        self.receipt = receipt
        self._type = State(initialValue: receipt.type ?? "Unknown type")
        self._description = State(initialValue: receipt.text ?? "")
        self._date = State(initialValue: receipt.date ?? Date())
        self._shortSerial = State(initialValue: receipt.serial ?? "")
        self._longSerial = State(initialValue: receipt.longSerial ?? "")
        self._sum = State(initialValue: String(receipt.sum))
        if let image = receipt.image {
            self._image = State(initialValue: UIImage(data: image))
        }
        print("epic")
    }

    var body: some View {
        Form {
            Section {
                Picker("Shop", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .frame(maxHeight: 400)
            }
            Group {
                Section(header: Text("Serial")) {
                    HStack {
                        TextField("Short serial", text: $shortSerial)
                            .keyboardType(.numberPad)
                        TextField("Long serial", text: $longSerial)
                            .keyboardType(.numberPad)
                    }
                }

                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                }

                Section(header: Text("Sum")) {
                    TextField("EUR", text: $sum)
                }
            }
            .headerProminence(.increased)

            loadImage

            Section {
                Button("Save") {
                    let receipt = self.receipt
                    receipt.type = self.type
                    receipt.serial = self.shortSerial
                    receipt.longSerial = self.longSerial
                    receipt.sum = (self.sum as NSString).floatValue
                    receipt.date = self.date
                    receipt.text = self.description

                    try? moc.save()
                }
            }
        }
        .navigationTitle("Edit receipt")
    }

    var loadImage: AnyView {
        guard let image = image else {
            return AnyView(Text("Image did not load"))
        }
        return AnyView(Image(uiImage: image).resizable().scaledToFit())
    }
}
