import SwiftUI

struct BackgroundImageView: View {
    @EnvironmentObject private var settings: AppSettings

    let isEnabled: Bool

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            if isEnabled,
               let imageURL = settings.backgroundImageURL,
               let image = NSImage(contentsOf: imageURL) {
                GeometryReader { proxy in
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .blur(radius: settings.backgroundImageBlur)
                        .opacity(settings.backgroundImageOpacity)
                }

                Color(nsColor: .windowBackgroundColor)
                    .opacity(0.46)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
