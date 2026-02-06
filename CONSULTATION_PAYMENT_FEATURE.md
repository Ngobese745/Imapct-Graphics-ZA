# Consultation Chat Payment Offer Feature

## Overview
This feature allows administrators to send payment offers to users in the consultation chat, enabling users to pay for services discussed using Paystack.

## Implementation Summary

### Files Modified
1. **`lib/screens/admin_consultation_chat_screen.dart`**
   - Added payment offer dialog for admins to create offers
   - Added payment offer message bubble display
   - Added "Send Offer" button in the AppBar
   - Implemented `_showPaymentOfferDialog()` and `_sendPaymentOffer()` methods

2. **`lib/screens/consultation_request_screen.dart`**
   - Added payment offer message bubble with "Pay Now" button
   - Implemented `_handlePayment()` method to process Paystack payments
   - Updated message bubble to display payment offers with status badges

## Features

### Admin Features
1. **Send Payment Offer**
   - Click the payment icon in the AppBar of the consultation chat
   - Enter service description (e.g., "Logo Design Package")
   - Enter amount in ZAR
   - Send offer to user

2. **Payment Offer Display**
   - Special payment offer bubble with gold "PAYMENT OFFER" badge
   - Displays service description and amount
   - Shows "PAID" badge when payment is completed
   - Timestamp showing when offer was sent

### User Features
1. **View Payment Offers**
   - Payment offers appear as special message bubbles in the chat
   - Clear display of service description and amount
   - Status indicators (Pending/Paid)

2. **Make Payment**
   - Click "Pay Now" button on the payment offer
   - Redirected to Paystack payment screen
   - Complete payment using Paystack
   - Payment status automatically updated in the chat

## Technical Details

### Message Structure
Payment offer messages are stored in Firestore with the following structure:

```javascript
{
  message: "Service description",
  senderId: "admin_uid",
  senderName: "Admin Name",
  senderType: "payment_offer",  // Special type for payment offers
  timestamp: Timestamp,
  read: false,
  offerId: "unique_offer_id",
  amount: 500.00,  // Amount in ZAR
  paymentStatus: "pending"  // pending, paid, or cancelled
}
```

### Payment Flow
1. Admin creates payment offer with description and amount
2. Offer is saved as a message in Firestore
3. User sees payment offer in chat with "Pay Now" button
4. User clicks "Pay Now" and is redirected to Paystack payment screen
5. After successful payment, message is updated with `paymentStatus: "paid"`
6. Both admin and user see the updated status in the chat

### Database Collections
- **consultations/{consultationId}/messages** - Stores all chat messages including payment offers
- Payment offers are identified by `senderType: "payment_offer"`

## Usage Instructions

### For Admins
1. Open a consultation chat from the admin dashboard
2. Click the payment icon (💳) in the top-right corner
3. Fill in the service description and amount
4. Click "Send Offer"
5. The payment offer will appear in the chat
6. Once the user pays, the offer will show a "PAID" badge

### For Users
1. Chat with admin in the consultation screen
2. When admin sends a payment offer, it will appear in the chat
3. Review the service description and amount
4. Click "Pay Now" to proceed with payment
5. Complete payment via Paystack
6. The offer will be marked as "PAID" after successful payment

## Integration with Paystack
- Uses existing `PaystackPaymentScreen` for payment processing
- Creates a `CartItem` with the service description
- Payment type is set to `consultation_service`
- Payment verification and order creation handled by existing Paystack service

## UI Design
- **Payment Offer Badge**: Gold background with "PAYMENT OFFER" text
- **Paid Badge**: Green background with "PAID" text
- **Amount Display**: Gold color with R prefix (e.g., "R 500.00")
- **Pay Now Button**: Dark red background with white text
- **Border**: Dark red 2px border around payment offer bubble

## Future Enhancements (Optional)
1. Add ability to cancel payment offers
2. Add payment expiration/deadline
3. Add payment history in user profile
4. Send notifications when payment offers are sent/paid
5. Add invoice generation for paid offers
6. Add partial payment support

