import SwiftUI
import Playgrounds

struct SampleImage: Decodable, Identifiable {
    let id: String
    let author: String?
    let width: Int?
    let height: Int?
    let url: String?
    let downloadURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case author
        case width
        case height
        case url
        case downloadURL = "download_url"
    }
}

struct ContentView: View {
    let urlString = "https://picsum.photos/v2/list"
    @State private var images: [SampleImage] = []
    
    var body: some View {
        List {
            ForEach(images) { image in
                ImageRow(sampleImage: image)
            }
        }
        .task {
            if let url = URL(string: urlString) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    images = try JSONDecoder().decode([SampleImage].self, from: data)
                } catch {
                    print(error)
                }
                
            }
            
        }
    }
}


struct ImageRow: View {
    @State private var image = UIImage(named: "sampleImage")
    let sampleImage: SampleImage
    
    var body: some View {
        Image(uiImage: image!)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .task {
                print("Started:", sampleImage.id)
                
                if let urlString = sampleImage.downloadURL,
                   let url = URL(string: urlString) {
                    do {
                       
                        image = try await DefaultImageKit.shared.loadImage(with: url)
                    } catch {
                        print(error.localizedDescription)
                        print("Task cancelled", sampleImage.id)
                    }
                    
                }
                
                print("Ended:", sampleImage.id)
            }
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}
