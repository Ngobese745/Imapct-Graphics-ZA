import * as crypto from 'crypto';
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// Initialize Firebase Admin
admin.initializeApp();

interface PaystackWebhookPayload {
    event: string;
    data: {
        reference: string;
        status: string;
        amount: number;
        customer: {
            email: string;
        };
        subscription_code?: string;
    };
}

/**
 * Paystack Webhook Handler
 * This function processes webhook notifications from Paystack
 */
export const paystackWebhook = functions.https.onRequest(async (req, res) => {
    // Only allow POST requests
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    try {
        const payload: PaystackWebhookPayload = req.body;
        const signature = req.headers['x-paystack-signature'] as string;

        console.log('Paystack webhook received:', payload.event);

        // Verify webhook signature (optional but recommended)
        // const isValidSignature = verifyWebhookSignature(JSON.stringify(payload), signature);
        // if (!isValidSignature) {
        //   console.error('Invalid webhook signature');
        //   res.status(400).send('Invalid signature');
        //   return;
        // }

        // Process the webhook event
        let result;
        switch (payload.event) {
            case 'charge.success':
                result = await handleSuccessfulPayment(payload.data);
                break;
            case 'subscription.create':
                result = await handleSubscriptionCreated(payload.data);
                break;
            case 'subscription.enable':
                result = await handleSubscriptionEnabled(payload.data);
                break;
            case 'subscription.disable':
                result = await handleSubscriptionDisabled(payload.data);
                break;
            default:
                console.log('Unhandled webhook event:', payload.event);
                result = { success: true, message: 'Event logged but not processed' };
        }

        res.status(200).json(result);
    } catch (error) {
        console.error('Error processing webhook:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

/**
 * Handle successful payment
 */
async function handleSuccessfulPayment(data: any) {
    try {
        const reference = data.reference;
        const status = data.status;
        const amount = data.amount / 100; // Convert from kobo to naira
        const customerEmail = data.customer?.email;

        console.log('Processing successful payment:', reference, amount);

        if (status !== 'success') {
            return {
                success: false,
                message: 'Payment not successful'
            };
        }

        // Find order by payment reference
        const ordersQuery = await admin.firestore()
            .collection('orders')
            .where('paymentReference', '==', reference)
            .limit(1)
            .get();

        if (!ordersQuery.empty) {
            const orderDoc = ordersQuery.docs[0];
            const orderData = orderDoc.data();

            // Update order status
            await orderDoc.ref.update({
                status: 'completed',
                paymentStatus: 'success',
                paymentVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Clear user cart
            const userId = orderData.userId;
            if (userId) {
                await admin.firestore().collection('users').doc(userId).update({
                    cart: [],
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }

            // Send notification
            await admin.firestore().collection('notifications').add({
                userId: userId,
                type: 'order',
                title: 'Payment Successful! 🎉',
                message: `Your order has been processed successfully. Order ID: ${orderDoc.id}`,
                data: {
                    orderId: orderDoc.id,
                    status: 'completed',
                    amount: amount
                },
                priority: 'high',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false
            });

            console.log('Order updated successfully:', orderDoc.id);
            return {
                success: true,
                message: 'Order processed successfully',
                orderId: orderDoc.id
            };
        } else {
            // Try to process from pending payment data
            const result = await processPendingPayment(reference, amount, customerEmail);
            return result;
        }
    } catch (error) {
        console.error('Error handling successful payment:', error);
        return {
            success: false,
            message: 'Error processing payment: ' + error.message
        };
    }
}

/**
 * Process pending payment data
 */
async function processPendingPayment(reference: string, amount: number, email?: string) {
    try {
        // Check for pending payment in Firestore
        const pendingPaymentsQuery = await admin.firestore()
            .collection('pending_payments')
            .where('reference', '==', reference)
            .limit(1)
            .get();

        if (!pendingPaymentsQuery.empty) {
            const pendingDoc = pendingPaymentsQuery.docs[0];
            const pendingData = pendingDoc.data();

            const cartItems = pendingData.cartItems;
            const userId = pendingData.userId;
            const customerName = pendingData.customerName;
            const customerEmail = pendingData.customerEmail;

            if (cartItems && userId) {
                // Create order
                const orderData = {
                    userId: userId,
                    customerName: customerName || email || 'Unknown',
                    customerEmail: customerEmail || email || '',
                    items: cartItems,
                    totalAmount: amount,
                    paymentReference: reference,
                    paymentStatus: 'success',
                    status: 'completed',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    paymentVerifiedAt: admin.firestore.FieldValue.serverTimestamp()
                };

                const orderDoc = await admin.firestore().collection('orders').add(orderData);

                // Clear cart
                await admin.firestore().collection('users').doc(userId).update({
                    cart: [],
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });

                // Delete pending payment document
                await pendingDoc.ref.delete();

                // Send notification
                await admin.firestore().collection('notifications').add({
                    userId: userId,
                    type: 'order',
                    title: 'Payment Successful! 🎉',
                    message: `Your order has been processed successfully. Order ID: ${orderDoc.id}`,
                    data: {
                        orderId: orderDoc.id,
                        status: 'completed',
                        amount: amount
                    },
                    priority: 'high',
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    isRead: false
                });

                console.log('Order created from pending payment:', orderDoc.id);
                return {
                    success: true,
                    message: 'Order created from pending payment',
                    orderId: orderDoc.id
                };
            }
        }

        return {
            success: false,
            message: 'No pending payment found for reference: ' + reference
        };
    } catch (error) {
        console.error('Error processing pending payment:', error);
        return {
            success: false,
            message: 'Error processing pending payment: ' + error.message
        };
    }
}

/**
 * Handle subscription created
 */
async function handleSubscriptionCreated(data: any) {
    try {
        console.log('Subscription created:', data.subscription_code);
        // Add subscription creation logic here
        return {
            success: true,
            message: 'Subscription created successfully'
        };
    } catch (error) {
        console.error('Error handling subscription created:', error);
        return {
            success: false,
            message: 'Error processing subscription: ' + error.message
        };
    }
}

/**
 * Handle subscription enabled
 */
async function handleSubscriptionEnabled(data: any) {
    try {
        console.log('Subscription enabled:', data.subscription_code);
        // Add subscription enabled logic here
        return {
            success: true,
            message: 'Subscription enabled successfully'
        };
    } catch (error) {
        console.error('Error handling subscription enabled:', error);
        return {
            success: false,
            message: 'Error processing subscription: ' + error.message
        };
    }
}

/**
 * Handle subscription disabled
 */
async function handleSubscriptionDisabled(data: any) {
    try {
        console.log('Subscription disabled:', data.subscription_code);
        // Add subscription disabled logic here
        return {
            success: true,
            message: 'Subscription disabled successfully'
        };
    } catch (error) {
        console.error('Error handling subscription disabled:', error);
        return {
            success: false,
            message: 'Error processing subscription: ' + error.message
        };
    }
}

/**
 * Verify webhook signature (optional)
 */
function verifyWebhookSignature(payload: string, signature: string): boolean {
    try {
        const secret = functions.config().paystack?.secret_key;
        if (!secret) {
            console.warn('Paystack secret key not configured');
            return true; // Skip verification if not configured
        }

        const computedSignature = 'sha256=' + crypto
            .createHmac('sha256', secret)
            .update(payload)
            .digest('hex');

        return computedSignature === signature;
    } catch (error) {
        console.error('Error verifying webhook signature:', error);
        return false;
    }
}
