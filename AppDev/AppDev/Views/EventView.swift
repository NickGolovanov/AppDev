import SwiftUI

struct EventView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Text("PartyPal")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.title2)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                        .overlay(Text("3").font(.caption2).foregroundColor(.white))
                        .offset(x: 8, y: -8)
                }
                Image("profile") // Replace with your profile image
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        // Event Image
                        AsyncImage(url: URL(string: "https://images.unsplash.com/photo-1464983953574-0892a716854b?auto=format&fit=crop&w=800&q=80")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                        }
                        HStack {
                            Button(action: {}) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "heart")
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    // Event Card
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("Tech Innovation Summit 2025")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.top, 8)
                        
                        // Date, Time, Location
                        HStack(spacing: 16) {
                            Label("May 15, 2025 · 9:00 AM", systemImage: "calendar")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundColor(.purple)
                            Text("Convention Center, Silicon Valley")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // Organizer
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: "https://randomuser.me/api/portraits/men/32.jpg")) { image in
                                image
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle().fill(Color(.systemGray4)).frame(width: 36, height: 36)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Organized by")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("TechEvents Inc.")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        // About Event
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Event")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Join us for the most anticipated tech event of 2025. Network with industry leaders, discover breakthrough innovations, and gain insights into the future of technology. This summit features keynote speakers from leading tech companies, hands-on workshops, and exclusive product launches.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // People Attending
                        VStack(alignment: .leading, spacing: 8) {
                            Text("People Attending")
                                .font(.headline)
                                .fontWeight(.semibold)
                            HStack(spacing: -12) {
                                ForEach(0..<4) { i in
                                    AsyncImage(url: URL(string: [
                                        "https://randomuser.me/api/portraits/men/31.jpg",
                                        "https://randomuser.me/api/portraits/women/44.jpg",
                                        "https://randomuser.me/api/portraits/men/45.jpg",
                                        "https://randomuser.me/api/portraits/women/46.jpg"
                                    ][i])) { image in
                                        image
                                            .resizable()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    } placeholder: {
                                        Circle().fill(Color(.systemGray4)).frame(width: 32, height: 32)
                                    }
                                }
                                ZStack {
                                    Circle().fill(Color(.systemGray4)).frame(width: 32, height: 32)
                                    Text("+42")
                                        .font(.caption)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        
                        // Price and Tickets
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Price per ticket")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("$299")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Available tickets")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("46 left")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Get Ticket Button
                        Button(action: {}) {
                            Text("Get Ticket Now")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color(.systemGray4), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 8)
                    .offset(y: -40)
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
        }
    }
}

#Preview {
    EventView()
}
