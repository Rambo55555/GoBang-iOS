//
//  ImageView.swift
//  GoBang
//
//  Created by Rambo on 2021/5/6.
//

import SwiftUI

struct ImageView: View {
    @EnvironmentObject var viewModel: ImageViewModel
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @GestureState private var gesturePanOffset: CGSize = .zero
    @State var geometrySize: CGSize = .zero
    @Binding var winState: Bool
    var isLoading: Bool {
        viewModel.backgroundURL != nil && viewModel.backgroundImage == nil
    }
    
    private var panOffset: CGSize {
        (viewModel.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private var zoomScale: CGFloat {
        viewModel.steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                self.viewModel.steadyStateZoomScale *= finalGestureScale
            }
    }
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in
            self.viewModel.steadyStatePanOffset = self.viewModel.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
        }
    }
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(viewModel.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            viewModel.steadyStatePanOffset = .zero
            viewModel.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: viewModel.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        .gesture(self.doubleTapToZoom(in: geometry.size))
                    if self.isLoading {
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    }
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onAppear(){
                    geometrySize = geometry.size
                    print("geometrySize: \(geometrySize)")
                    viewModel.getImageUrl(type: winState ? "win" : "lose") {
                        print("fetch background image......")
                        viewModel.fetchBackgroundImageData() {
                            self.zoomToFit(viewModel.backgroundImage, in: geometrySize)
                        }
                    }
                    
                }
//                .onReceive(self.document.$backgroundImage) { image in
//                    self.zoomToFit(image, in: geometry.size)
//                }
//                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
//                    var location = geometry.convert(location, from: .global)
//                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
//                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
//                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
//                    return self.drop(providers: providers, at: location)
//                }
//                .navigationBarItems(trailing: Button(action: {
//                    if let url = UIPasteboard.general.url, url != self.document.backgroundURL {
//                        self.confirmBackgroundPaste = true
//                    } else {
//                        self.explainBackgroundPaste = true
//                    }
//                }, label: {
//                    Image(systemName: "doc.on.clipboard").imageScale(.large)
//                        .alert(isPresented: self.$explainBackgroundPaste) {
//                            return Alert(
//                                title: Text("Paste Background"),
//                                message: Text("Copy the URL of an image to the clip board and touch this button to make it the background of your document."),
//                                dismissButton: .default(Text("OK"))
//                            )
//                        }
//                }))
            }
            .zIndex(-1)
            HStack {
                Button("点我") {
                    viewModel.getImageUrl(type: winState ? "win" : "lose") {
                        print("fetch background image......")
                        viewModel.fetchBackgroundImageData() {
                            self.zoomToFit(viewModel.backgroundImage, in: geometrySize)
                        }
                        
                    }
                }
//                Button("别点我") {
//                    viewModel.getImageUrl(type: "lose") {
//                        print("fetch background image......")
//                        viewModel.fetchBackgroundImageData() {
//                            self.zoomToFit(viewModel.backgroundImage, in: geometrySize)
//                        }
//                    }
//                }
            }
        }
    }
}

//struct ImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        ImageView().environmentObject(ImageViewModel())
//    }
//    
//}
