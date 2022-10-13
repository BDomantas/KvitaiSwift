//
//  ContentView.swift
//  kvitai
//
//  Created by Domantas Bernatavicius on 2022-06-21.
//

import SwiftUI

struct ContentView: View {
    @State private var showScannerSheet = false
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.date)
    ]) var receipts: FetchedResults<Receipt>

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(receipts) { receipt in
                        NavigationLink {
                            ReceiptView(receipt: receipt)
                        }
                            label: {
                            HStack {
                                ShopLogo(type: receipt.type ?? "IKI")
                                VStack(alignment: .leading) {
                                    Text(receipt.type ?? "Unknown").font(.largeTitle)
                                    Text(receipt.date?.formatted(date: .numeric, time: .omitted) ?? "")
                                }
                                Spacer()
                                Text("\(String(receipt.sum)) EUR")
                            }
                        }
                    }.onDelete(perform: deleteReceipt)
                }
            }
            .navigationTitle("Scan some receipt")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.showScannerSheet.toggle()
                    } label: {
                        Image(systemName: "doc.text.viewfinder").font(.title)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showScannerSheet, content: {
                self.makeScannerView()
            })
        }
    }

    private func makeScannerView() -> ScannerView {
        ScannerView()
    }

    func deleteReceipt(at offsets: IndexSet) {
        for offset in offsets {
            let receipt = receipts[offset]
            moc.delete(receipt)
        }
        try? moc.save()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
