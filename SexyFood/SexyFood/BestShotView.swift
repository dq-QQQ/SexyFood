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
    @StateObject private var viewModel = BestShotViewModel()

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(viewModel.selectableImages) { item in
                        ZStack {
                            Image(uiImage: item.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(item.isSelected ? Color.blue : Color.clear, lineWidth: 4)
                                )
                        }
                        .onTapGesture {
                            viewModel.toggleSelection(for: item.id)
                        }
                    }
                }
                .padding()
            }
            
            Button("선택한 베스트샷 저장하기") {
                let bestShots = viewModel.selectedImages
                viewModel.saveSelectedImagesToAlbum()
                print("베스트샷 개수: \(bestShots.count)")
            }
            .padding()
        }
        .onAppear {
            viewModel.loadTodaysPhotos()
        }
    }
}


struct SelectableImage: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    var isSelected: Bool = false
}



class BestShotViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
        @Published var selectableImages: [SelectableImage] = []
        
        // 사진 로드
        func loadTodaysPhotos() {
            fetchTodaysPhotos { [weak self] fetchedAssets in
                guard let self else { return }
                Task { @MainActor in
                    self.assets = fetchedAssets
                    self.selectableImages = []
                    
                    for asset in fetchedAssets {
                        await self.appendImage(for: asset)
                    }
                }
            }
        }
        
        private func appendImage(for asset: PHAsset) async {
            await withCheckedContinuation { continuation in
                requestImage(for: asset) { image in
                    if let image {
                        DispatchQueue.main.async {
                            self.selectableImages.append(SelectableImage(image: image))
                        }
                    }
                    continuation.resume()
                }
            }
        }
        
        // 선택 토글
        func toggleSelection(for id: UUID) {
            if let index = selectableImages.firstIndex(where: { $0.id == id }) {
                selectableImages[index].isSelected.toggle()
            }
        }
        
        // 선택된 베스트샷 가져오기
        var selectedImages: [UIImage] {
            selectableImages.filter { $0.isSelected }.map { $0.image }
        }

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

import Photos

extension BestShotViewModel {
    func saveSelectedImagesToAlbum(albumName: String = "SexyFood BestShots") {
        let imagesToSave = selectedImages
        guard !imagesToSave.isEmpty else {
            print("저장할 이미지가 없습니다.")
            return
        }

        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                print("사진 접근 권한이 없습니다.")
                return
            }

            self.getOrCreateAlbum(named: albumName) { album in
                guard let album = album else {
                    print("앨범 생성/찾기에 실패했습니다.")
                    return
                }

                PHPhotoLibrary.shared().performChanges {
                    for image in imagesToSave {
                        let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                        if let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                           let placeholder = request.placeholderForCreatedAsset {
                            albumChangeRequest.addAssets([placeholder] as NSArray)
                        }
                    }
                } completionHandler: { success, error in
                    if success {
                        print("✅ 선택한 사진을 앨범 '\(albumName)'에 저장 완료")
                    } else if let error = error {
                        print("⚠️ 저장 오류: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func getOrCreateAlbum(named: String, completion: @escaping (PHAssetCollection?) -> Void) {
        // 앨범 있는지 찾기
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", named)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let album = collection.firstObject {
            completion(album)
            return
        }

        // 없으면 생성
        var albumPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: named)
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }) { success, error in
            if success, let placeholder = albumPlaceholder {
                let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                completion(collectionFetchResult.firstObject)
            } else {
                print("⚠️ 앨범 생성 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                completion(nil)
            }
        }
    }
}
