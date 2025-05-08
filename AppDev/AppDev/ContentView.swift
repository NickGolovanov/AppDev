//
//  ContentView.swift
//  AppDev
//
//  Created by Nikita Golovanov on 5/3/25.
//

import SwiftUI
import MapKit

struct Ticket: Identifiable {
    let id = UUID()
    let eventName: String
    let date: String
    let location: String
    let name: String
    let email: String
    let price: String
}

struct ContentView: View {
    let tickets = [
        Ticket(eventName: "Amsterdam Student Night", date: "May 15, 2025 - 22:00", location: "Club Paradise, Amsterdam", name: "John Doe", email: "john.doe@student.uva.nl", price: "€15.00"),
        Ticket(eventName: "Rotterdam Beach Party", date: "May 20, 2025 - 14:00", location: "Hoek van Holland Beach", name: "John Doe", email: "john.doe@student.uva.nl", price: "€20.00")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PartyPal")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(Color.purple)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                        .overlay(Text("3").font(.caption2).foregroundColor(.white))
                        .offset(x: 10, y: -10)
                }
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 4)
            .background(Color.white)
            .shadow(color: Color(.systemGray5), radius: 1, y: 1)
            
            // Title
            HStack {
                Text("My Tickets")
                    .font(.title).fontWeight(.heavy)
                Spacer()
            }
            .padding([.horizontal, .top])
            
            // Tickets List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tickets) { ticket in
                        TicketCard(ticket: ticket)
                    }
                }
                .padding()
            }
            
            // Bottom Tab Bar
            Divider()
            HStack {
                TabBarItem(icon: "house", label: "Home", isSelected: false)
                Spacer()
                TabBarItem(icon: "ticket", label: "Tickets", isSelected: true)
                Spacer()
                TabBarItem(icon: "calendar", label: "Events", isSelected: false)
                Spacer()
                TabBarItem(icon: "bubble.left.and.bubble.right", label: "Chat", isSelected: false)
                Spacer()
                TabBarItem(icon: "person", label: "Profile", isSelected: false)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .shadow(color: Color(.systemGray5), radius: 2, y: -2)
        }
        .background(Color(.systemGray6).ignoresSafeArea())
    }
}

struct TicketCard: View {
    let ticket: Ticket
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ticket.eventName)
                .font(.headline)
                .fontWeight(.semibold)
            HStack(spacing: 12) {
                Label(ticket.date, systemImage: "calendar")
                    .font(.subheadline)
                Spacer()
            }
            HStack(spacing: 12) {
                Label(ticket.location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                Spacer()
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Name: ") + Text(ticket.name).fontWeight(.medium)
                Text("Email: ") + Text(ticket.email).fontWeight(.medium)
                Text("Ticket Price: ") + Text(ticket.price).fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            Spacer(minLength: 8)
            Rectangle()
                .fill(Color.black)
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(.systemGray4).opacity(0.2), radius: 6, x: 0, y: 2)
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isSelected ? Color.purple : Color.gray)
            Text(label)
                .font(.caption)
                .foregroundColor(isSelected ? Color.purple : Color.gray)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
