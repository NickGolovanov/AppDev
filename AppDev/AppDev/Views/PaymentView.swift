import SwiftUI
import StripePaymentSheet

struct PaymentView: View {
    @StateObject private var paymentViewModel = PaymentViewModel()
    let amount: Int
    let eventTitle: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Purchase Ticket")
                .font(.title)
                .fontWeight(.bold)
            
            Text(eventTitle)
                .font(.headline)
            
            Text("Amount: $\(Double(amount) / 100.0, specifier: "%.2f")")
                .font(.title2)
            
            if paymentViewModel.isLoading {
                ProgressView()
            } else if let error = paymentViewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else if let paymentSheet = paymentViewModel.paymentSheet {
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: paymentViewModel.onPaymentCompletion
                ) {
                    Text("Pay Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            paymentViewModel.preparePaymentSheet(amount: amount)
        }
    }
} 