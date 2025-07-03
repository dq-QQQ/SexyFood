//
//  BestShotView.swift
//  SexyFood
//
//  Created by Kyu jin Lee on 6/26/25.
//

import Foundation
import SwiftUI
import Photos

struct BestShotView: View {
    var viewModel = BestShotViewModel()
    
    @State private var assets: [PHAsset] = []
    @State private var images: [UIImage] = []
    @State private var selectedImage: UIImage?


    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(images, id: \.self) { uiImage in
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.fetchTodaysPhotos { fetchedAssets in
                assets = fetchedAssets
                images = [] // 초기화 후 다시 채움
                for asset in assets {
                    viewModel.requestImage(for: asset) { image in
                        if let image = image {
                            DispatchQueue.main.async {
                                images.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
}


class BestShotViewModel: ObservableObject {

    func fetchTodaysPhotos(completion: @escaping ([PHAsset]) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
            fatalError("Unable to calculate end of day")
        }
        // 📌 오늘 00:00 이후로 찍힌 사진을 찾는다
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d AND creationDate >= %@ AND creationDate <= %@", PHAssetMediaType.image.rawValue, startOfDay as NSDate, endOfDay as NSDate)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let results = PHAsset.fetchAssets(with: options)

        var assets: [PHAsset] = []
        results.enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }

        completion(assets)
    }

    func requestImage(for asset: PHAsset, targetSize: CGSize = CGSize(width: 300, height: 300), completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            completion(image)
        }
    }

    
}

