const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const { onDocumentCreated: onDocumentCreatedV2 } = require('firebase-functions/v2/firestore');
const { onCall: onCallV2, onRequest: onRequestV2, onRequest } = require('firebase-functions/v2/https');

admin.initializeApp();

// Simple Paystack webhook handler
exports.paystackWebhook = functions.https.onRequest(async (req, res) => {
  try {
    console.log('🔔 Paystack webhook received');

    // Only accept POST requests
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    const event = req.body;
    console.log('📋 Event type:', event.event);
    console.log('📋 Event data:', JSON.stringify(event.data, null, 2));

    // Handle successful payment
    if (event.event === 'charge.success') {
      await handleSuccessfulPayment(event.data);
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('❌ Webhook error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Handle successful payment
async function handleSuccessfulPayment(paymentData) {
  try {
    console.log('✅ Processing successful payment:', paymentData.reference);

    const reference = paymentData.reference;
    const amount = paymentData.amount / 100; // Convert from kobo to naira/rand
    const customerEmail = paymentData.customer?.email;

    console.log('💰 Payment details:', {
      reference,
      amount,
      customerEmail
    });

    // Find the user by email
    const userQuery = await admin.firestore()
      .collection('users')
      .where('email', '==', customerEmail)
      .limit(1)
      .get();

    if (userQuery.empty) {
      console.log('❌ User not found for email:', customerEmail);
      return;
    }

    const userDoc = userQuery.docs[0];
    const userId = userDoc.id;

    console.log('👤 Found user:', userId);

    // Update wallet balance in both collections for consistency
    const walletRef = admin.firestore().collection('wallets').doc(userId);
    const userRef = admin.firestore().collection('users').doc(userId);

    // Update wallets collection
    await walletRef.set({
      balance: admin.firestore.FieldValue.increment(amount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // Also update users collection for consistency
    await userRef.update({
      walletBalance: admin.firestore.FieldValue.increment(amount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('💰 Wallet balance updated in both collections');

    // Create transaction record
    await admin.firestore().collection('transactions').add({
      userId: userId,
      amount: amount,
      transactionId: reference,
      status: 'completed',
      type: 'payment',
      description: 'Wallet Funding',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Transaction record created');

    // Send success notification
    await admin.firestore().collection('updates').add({
      userId: userId,
      title: 'Payment Successful! 🎉',
      message: `Your payment of R${amount.toFixed(2)} has been processed successfully. Reference: ${reference}`,
      type: 'payment_success',
      action: 'payment_success',
      isRead: false,
      data: {
        transactionId: reference,
        amount: amount,
        reference: reference,
        orderNumber: reference
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('📱 Success notification sent');

    // Send invoice email
    await sendInvoiceEmail(userId, amount, reference, customerEmail);

    // Update invoice status if this is an invoice payment
    await updateInvoiceStatus(reference, customerEmail, amount);

  } catch (error) {
    console.error('❌ Error processing successful payment:', error);
  }
}

// Send invoice email
async function sendInvoiceEmail(userId, amount, reference, customerEmail) {
  try {
    console.log('📧 Sending invoice email...');

    // Get user details
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData) {
      console.log('❌ User data not found for email');
      return;
    }

    // Create invoice email data
    const invoiceData = {
      to: customerEmail,
      subject: `Payment Invoice - R${amount.toFixed(2)} - ${reference}`,
      template: 'payment_invoice',
      data: {
        customerName: userData.name || 'Customer',
        amount: amount,
        reference: reference,
        date: new Date().toLocaleDateString('en-ZA'),
        time: new Date().toLocaleTimeString('en-ZA'),
        description: 'Wallet Funding'
      }
    };

    // Store email in Firestore for processing
    await admin.firestore().collection('email_queue').add({
      ...invoiceData,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: userId
    });

    console.log('📧 Invoice email queued for sending');
  } catch (error) {
    console.error('❌ Error sending invoice email:', error);
  }
}

// Update invoice status when payment is received
async function updateInvoiceStatus(reference, customerEmail, amount) {
  try {
    console.log('📋 Checking for invoice to update...');
    console.log('Reference:', reference);
    console.log('Customer Email:', customerEmail);
    console.log('Amount:', amount);

    // Look for invoice with matching reference or customer email and amount
    const invoiceQuery = await admin.firestore()
      .collection('invoices')
      .where('status', '==', 'pending')
      .where('customerEmail', '==', customerEmail)
      .get();

    console.log(`📋 Found ${invoiceQuery.docs.length} pending invoices for ${customerEmail}`);

    let invoiceToUpdate = null;

    // First try to find by exact reference match
    for (const doc of invoiceQuery.docs) {
      const invoiceData = doc.data();
      if (invoiceData.reference === reference ||
        invoiceData.invoiceNumber === reference ||
        invoiceData.orderId === reference) {
        invoiceToUpdate = { id: doc.id, data: invoiceData };
        console.log('✅ Found invoice by reference match:', doc.id);
        break;
      }
    }

    // If no reference match, try to find by amount match (within R1 tolerance)
    if (!invoiceToUpdate) {
      for (const doc of invoiceQuery.docs) {
        const invoiceData = doc.data();
        const invoiceAmount = invoiceData.amount || 0;
        const amountDifference = Math.abs(invoiceAmount - amount);

        if (amountDifference <= 1.0) { // Within R1 tolerance
          invoiceToUpdate = { id: doc.id, data: invoiceData };
          console.log('✅ Found invoice by amount match:', doc.id, 'Amount diff:', amountDifference);
          break;
        }
      }
    }

    if (invoiceToUpdate) {
      // Update the invoice status to paid
      await admin.firestore()
        .collection('invoices')
        .doc(invoiceToUpdate.id)
        .update({
          status: 'paid',
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          paymentReference: reference,
          paymentMethod: 'paystack'
        });

      console.log('✅ Invoice status updated to PAID:', invoiceToUpdate.id);
      console.log('📋 Invoice Number:', invoiceToUpdate.data.invoiceNumber);
      console.log('💰 Amount:', invoiceToUpdate.data.amount);

      // Send notification to admin about invoice payment
      await admin.firestore().collection('updates').add({
        userId: 'admin', // Special admin user ID
        title: 'Invoice Payment Received! 💰',
        message: `Invoice ${invoiceToUpdate.data.invoiceNumber} has been paid by ${customerEmail} for R${amount.toFixed(2)}`,
        type: 'invoice_payment',
        action: 'invoice_paid',
        isRead: false,
        data: {
          invoiceId: invoiceToUpdate.id,
          invoiceNumber: invoiceToUpdate.data.invoiceNumber,
          customerEmail: customerEmail,
          amount: amount,
          reference: reference
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log('📱 Admin notification sent for invoice payment');
    } else {
      console.log('⚠️ No matching pending invoice found for this payment');
      console.log('Reference:', reference);
      console.log('Email:', customerEmail);
      console.log('Amount:', amount);
    }

  } catch (error) {
    console.error('❌ Error updating invoice status:', error);
  }
}

// Manual trigger for automated billing (for testing) - HTTP version
exports.manualAutoBillingHTTP = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const result = await manualAutoBillingLogic();
    res.status(200).json(result);
  } catch (error) {
    console.error('❌ Manual auto billing HTTP error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Manual trigger for automated billing (for testing) - Callable version
exports.manualAutoBilling = functions.https.onCall(async (data, context) => {
  return await manualAutoBillingLogic();
});

// Shared logic for manual auto billing
async function manualAutoBillingLogic() {
  console.log('🔄 Starting manual automated billing process...');

  try {
    // Get today's date
    const today = new Date();
    console.log(`📅 Checking for packages due on: ${today.toISOString().split('T')[0]}`);

    // Query packages due for billing today
    const packagesQuery = admin.firestore()
      .collection('package_subscriptions')
      .where('nextBillingDate', '<=', admin.firestore.Timestamp.fromDate(today))
      .where('status', '==', 'active');

    const snapshot = await packagesQuery.get();

    if (snapshot.empty) {
      console.log('✅ No packages due for billing today');
      return { success: true, message: 'No packages due for billing today', processed: 0 };
    }

    console.log(`📦 Found ${snapshot.size} packages due for billing`);

    const billingResults = [];

    // Process each package
    for (const doc of snapshot.docs) {
      try {
        const packageData = doc.data();
        const packageId = doc.id;

        console.log(`📧 Processing package: ${packageId}`);
        console.log(`👤 Client: ${packageData.clientName} (${packageData.clientEmail})`);
        console.log(`💰 Amount: R${packageData.packagePrice}`);

        // Send invoice email
        const emailResult = await sendAutoInvoiceEmail({
          clientName: packageData.clientName,
          clientEmail: packageData.clientEmail,
          packageName: packageData.packageName,
          packagePrice: packageData.packagePrice,
          billingCycle: packageData.billingCycle,
          nextBillingDate: packageData.nextBillingDate.toDate(),
          packageId: packageId,
        });

        if (emailResult.success) {
          console.log(`✅ Invoice email sent for package ${packageId}`);

          // Update next billing date
          const nextBillingDate = calculateNextBillingDate(
            packageData.nextBillingDate.toDate(),
            packageData.billingCycle
          );

          await admin.firestore()
            .collection('package_subscriptions')
            .doc(packageId)
            .update({
              nextBillingDate: admin.firestore.Timestamp.fromDate(nextBillingDate),
              lastBillingDate: admin.firestore.Timestamp.fromDate(today),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

          console.log(`📅 Next billing date updated to: ${nextBillingDate.toISOString().split('T')[0]}`);

          billingResults.push({
            packageId,
            clientName: packageData.clientName,
            clientEmail: packageData.clientEmail,
            success: true,
            messageId: emailResult.messageId,
          });
        } else {
          console.error(`❌ Failed to send email for package ${packageId}: ${emailResult.message}`);
          billingResults.push({
            packageId,
            clientName: packageData.clientName,
            clientEmail: packageData.clientEmail,
            success: false,
            error: emailResult.message,
          });
        }
      } catch (error) {
        console.error(`❌ Error processing package ${doc.id}:`, error);
        billingResults.push({
          packageId: doc.id,
          success: false,
          error: error.message,
        });
      }
    }

    console.log(`🎉 Automated billing completed. Processed ${billingResults.length} packages`);
    console.log('📊 Results:', billingResults);

    return {
      success: true,
      processed: billingResults.length,
      results: billingResults,
    };

  } catch (error) {
    console.error('❌ Automated billing error:', error);
    return {
      success: false,
      error: error.message,
    };
  }
}

// Calculate next billing date based on cycle
function calculateNextBillingDate(currentDate, billingCycle) {
  const nextDate = new Date(currentDate);

  switch (billingCycle.toLowerCase()) {
    case 'monthly':
      nextDate.setMonth(nextDate.getMonth() + 1);
      break;
    case 'quarterly':
      nextDate.setMonth(nextDate.getMonth() + 3);
      break;
    case 'yearly':
    case 'annually':
      nextDate.setFullYear(nextDate.getFullYear() + 1);
      break;
    default:
      // Default to monthly if cycle is not recognized
      nextDate.setMonth(nextDate.getMonth() + 1);
      break;
  }

  return nextDate;
}

// Send automated invoice email
async function sendAutoInvoiceEmail({
  clientName,
  clientEmail,
  packageName,
  packagePrice,
  billingCycle,
  nextBillingDate,
  packageId,
}) {
  try {
    console.log('📧 Preparing automated invoice email...');

    // Calculate amount in Rand for Paystack
    const amountInRand = Math.round(packagePrice);
    const baseUrl = 'https://paystack.shop/pay/n6c6hp792r';
    const paymentLink = `${baseUrl}?amount=${amountInRand}&email=${encodeURIComponent(clientEmail)}&name=${encodeURIComponent(clientName)}`;

    console.log(`🔗 Generated payment link: ${paymentLink}`);

    // Format dates and prices
    const formattedPrice = `R ${packagePrice.toFixed(2)}`;
    const formattedDate = nextBillingDate.toLocaleDateString('en-ZA', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
    const invoiceNumber = `PKG-${packageId.substring(0, 8).toUpperCase()}`;

    // Build email template
    const emailBody = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Monthly Invoice - Impact Graphics ZA</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #8B0000; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
          .invoice-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #8B0000; }
          .payment-button { display: inline-block; background: #8B0000; color: white; padding: 15px 30px; text-decoration: none; border-radius: 8px; font-weight: bold; margin: 20px 0; }
          .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📧 Monthly Invoice</h1>
            <p>Impact Graphics ZA</p>
          </div>
          <div class="content">
            <h2>Hello ${clientName}!</h2>
            <p>Your monthly subscription invoice is ready for payment.</p>
            
            <div class="invoice-details">
              <h3>📋 Invoice Details</h3>
              <p><strong>Package:</strong> ${packageName}</p>
              <p><strong>Amount:</strong> ${formattedPrice}</p>
              <p><strong>Billing Cycle:</strong> ${billingCycle}</p>
              <p><strong>Due Date:</strong> ${formattedDate}</p>
              <p><strong>Invoice #:</strong> ${invoiceNumber}</p>
            </div>

            <div style="text-align: center;">
              <a href="${paymentLink}" class="payment-button">💳 Pay Now</a>
            </div>

            <p>If you have any questions about this invoice, please contact us at <a href="mailto:info@impactgraphicsza.co.za">info@impactgraphicsza.co.za</a></p>
            
            <div class="footer">
              <p>Thank you for your continued business!</p>
              <p>Impact Graphics ZA Team</p>
            </div>
          </div>
        </div>
      </body>
      </html>
    `;

    // Create email document for MailerSend extension
    const emailData = {
      to: [
        { email: clientEmail, name: clientName },
      ],
      subject: `Monthly Invoice for ${packageName} - Impact Graphics ZA`,
      html: emailBody,
      from: {
        email: 'noreply@impactgraphicsza.co.za',
        name: 'Impact Graphics ZA',
      },
      reply_to: {
        email: 'info@impactgraphicsza.co.za',
        name: 'Impact Graphics ZA Support',
      },
      variables: [
        {
          email: clientEmail,
          substitutions: [
            { var: 'client_name', value: clientName },
            { var: 'package_name', value: packageName },
            { var: 'package_price', value: formattedPrice },
            { var: 'billing_cycle', value: billingCycle },
            { var: 'next_billing_date', value: formattedDate },
            { var: 'invoice_number', value: invoiceNumber },
            { var: 'payment_link', value: paymentLink },
          ],
        },
      ],
      tags: ['package', 'invoice', 'subscription', 'auto-billing'],
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      source: 'auto-billing',
    };

    console.log('📧 Adding automated invoice email to Firestore...');

    // Write to Firestore emails collection to trigger MailerSend extension
    const docRef = await admin.firestore().collection('emails').add(emailData);

    console.log(`✅ Automated invoice email queued with ID: ${docRef.id}`);

    return {
      success: true,
      message: 'Automated invoice email queued successfully',
      messageId: docRef.id,
    };

  } catch (error) {
    console.error('❌ Error sending automated invoice email:', error);
    return {
      success: false,
      message: `Error: ${error.message}`,
    };
  }
}

// Automated Billing Cloud Function - Scheduled
exports.autoBilling = functions.scheduler.onSchedule({
  schedule: '0 9 * * *',
  timeZone: 'Africa/Johannesburg'
}, async (event) => {
  console.log('🔄 Starting scheduled automated billing process...');

  try {
    // Get today's date
    const today = new Date();
    console.log(`📅 Checking for packages due on: ${today.toISOString().split('T')[0]}`);

    // Query packages due for billing today
    const packagesQuery = admin.firestore()
      .collection('package_subscriptions')
      .where('nextBillingDate', '<=', admin.firestore.Timestamp.fromDate(today))
      .where('status', '==', 'active');

    const snapshot = await packagesQuery.get();

    if (snapshot.empty) {
      console.log('✅ No packages due for billing today');
      return null;
    }

    console.log(`📦 Found ${snapshot.size} packages due for billing`);

    const billingResults = [];

    // Process each package
    for (const doc of snapshot.docs) {
      try {
        const packageData = doc.data();
        const packageId = doc.id;

        console.log(`📧 Processing package: ${packageId}`);
        console.log(`👤 Client: ${packageData.clientName} (${packageData.clientEmail})`);
        console.log(`💰 Amount: R${packageData.packagePrice}`);

        // Send invoice email
        const emailResult = await sendAutoInvoiceEmail({
          clientName: packageData.clientName,
          clientEmail: packageData.clientEmail,
          packageName: packageData.packageName,
          packagePrice: packageData.packagePrice,
          billingCycle: packageData.billingCycle,
          nextBillingDate: packageData.nextBillingDate.toDate(),
          packageId: packageId,
        });

        if (emailResult.success) {
          console.log(`✅ Invoice email sent for package ${packageId}`);

          // Update next billing date
          const nextBillingDate = calculateNextBillingDate(
            packageData.nextBillingDate.toDate(),
            packageData.billingCycle
          );

          await admin.firestore()
            .collection('package_subscriptions')
            .doc(packageId)
            .update({
              nextBillingDate: admin.firestore.Timestamp.fromDate(nextBillingDate),
              lastBillingDate: admin.firestore.Timestamp.fromDate(today),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

          console.log(`📅 Next billing date updated to: ${nextBillingDate.toISOString().split('T')[0]}`);

          billingResults.push({
            packageId,
            clientName: packageData.clientName,
            clientEmail: packageData.clientEmail,
            success: true,
            messageId: emailResult.messageId,
          });
        } else {
          console.error(`❌ Failed to send email for package ${packageId}: ${emailResult.message}`);
          billingResults.push({
            packageId,
            clientName: packageData.clientName,
            clientEmail: packageData.clientEmail,
            success: false,
            error: emailResult.message,
          });
        }
      } catch (error) {
        console.error(`❌ Error processing package ${doc.id}:`, error);
        billingResults.push({
          packageId: doc.id,
          success: false,
          error: error.message,
        });
      }
    }

    console.log(`🎉 Automated billing completed. Processed ${billingResults.length} packages`);
    console.log('📊 Results:', billingResults);

    return {
      success: true,
      processed: billingResults.length,
      results: billingResults,
    };

  } catch (error) {
    console.error('❌ Automated billing error:', error);
    throw error;
  }
});

// Update package billing date to today (for testing)
exports.updatePackageDate = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    console.log('🔄 Updating package billing date to today...');

    // Get today's date
    const today = new Date();
    console.log(`📅 Setting billing date to: ${today.toISOString().split('T')[0]}`);

    // Find packages for Colane Ngobese
    const packagesQuery = admin.firestore()
      .collection('package_subscriptions')
      .where('clientEmail', '==', 'colane.comfort.5@gmail.com')
      .where('status', '==', 'active');

    const snapshot = await packagesQuery.get();

    if (snapshot.empty) {
      console.log('❌ No packages found for colane.comfort.5@gmail.com');
      res.status(404).json({ error: 'No packages found for colane.comfort.5@gmail.com' });
      return;
    }

    console.log(`📦 Found ${snapshot.size} packages for Colane Ngobese`);

    const updatedPackages = [];

    // Update each package's billing date to today
    for (const doc of snapshot.docs) {
      const packageData = doc.data();
      console.log(`📧 Updating package: ${doc.id} - ${packageData.packageName}`);

      await admin.firestore()
        .collection('package_subscriptions')
        .doc(doc.id)
        .update({
          nextBillingDate: admin.firestore.Timestamp.fromDate(today),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`✅ Updated package ${doc.id} billing date to today`);
      updatedPackages.push({
        id: doc.id,
        packageName: packageData.packageName,
        clientName: packageData.clientName,
        clientEmail: packageData.clientEmail,
      });
    }

    console.log('🎉 All packages updated!');
    res.status(200).json({
      success: true,
      message: 'Packages updated successfully',
      updatedPackages: updatedPackages,
    });

  } catch (error) {
    console.error('❌ Error updating packages:', error);
    res.status(500).json({ error: error.message });
  }
});

// Image Proxy Cloud Function
// Proxies external images to bypass CORS restrictions
exports.imageProxy = functions.https.onRequest(async (req, res) => {
  // Set CORS headers to allow requests from your app
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Only allow GET requests
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    // Get the image URL from query parameter
    const imageUrl = req.query.url;

    if (!imageUrl) {
      res.status(400).json({ error: 'Missing url parameter' });
      return;
    }

    // Validate URL
    try {
      new URL(imageUrl);
    } catch (error) {
      res.status(400).json({ error: 'Invalid URL format' });
      return;
    }

    console.log('🖼️ Proxying image:', imageUrl);

    // Fetch the image from the external source
    const response = await axios.get(imageUrl, {
      responseType: 'arraybuffer',
      timeout: 15000,
      maxContentLength: 10 * 1024 * 1024, // 10MB max
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; ImpactGraphicsBot/1.0)',
        'Accept': 'image/*',
      },
    });

    // Get content type from response
    const contentType = response.headers['content-type'] || 'image/jpeg';

    // Set appropriate headers
    res.set('Content-Type', contentType);
    res.set('Cache-Control', 'public, max-age=86400'); // Cache for 24 hours
    res.set('Access-Control-Allow-Origin', '*');

    // Send the image data
    res.send(Buffer.from(response.data));

    console.log(`✅ Successfully proxied image from ${new URL(imageUrl).hostname}`);

  } catch (error) {
    console.error('❌ Error proxying image:', error.message);

    // Return error response
    if (error.response) {
      res.status(error.response.status).json({
        error: 'Failed to fetch image',
        status: error.response.status,
      });
    } else if (error.code === 'ECONNABORTED') {
      res.status(504).json({ error: 'Request timeout' });
    }
  }
});

// ==========================================
// WhatsApp & OpenRouter Integration (v2)
// ==========================================

// Imports moved to top of file

// Secrets are now fetched from Firestore (system_settings/secrets)
const YOUR_SITE_URL = 'https://impactgraphicsza.co.za';
const YOUR_SITE_NAME = 'Impact Graphics ZA';

// Helper to fetch secrets (openrouter_key, wesander_key, wesander_secret)
async function getSecrets() {
  try {
    const secretsDoc = await admin.firestore().collection('system_settings').doc('secrets').get();
    if (secretsDoc.exists) {
      return secretsDoc.data();
    }
  } catch (e) {
    console.warn('❌ Failed to fetch secrets from Firestore:', e.message);
  }
  return {};
}

// 1. WhatsApp Webhook (Receives messages from WeSander)
exports.whatsappWebhook = onRequestV2({ cors: true }, async (req, res) => {
  // CORS handled by v2 option
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    console.log('🔍 INCOMING WEBHOOK:', JSON.stringify(req.body, null, 2));
    console.log('🔍 HEADERS:', JSON.stringify(req.headers, null, 2));

    // DEBUG: Capture payload to Firestore
    await admin.firestore().collection('system_settings').doc('last_webhook_payload').set({
      body: req.body,
      headers: req.headers,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // --- Security: Verify Signature ---
    const secrets = await getSecrets();
    const wesanderSecret = secrets.wesander_secret || 'd0d90f28fd85f0408796110524b61650';

    const signature = req.headers['x-webhook-signature'];
    if (!signature) {
      // console.warn('⚠️ Webhook missing Checksum/Signature');
    } else {
      if (signature !== wesanderSecret) {
        console.warn('⛔️ Webhook Signature Mismatch!');
        res.status(403).send('Invalid Signature');
        return;
      }
    }
    // ----------------------------------

    const body = req.body;

    // Safety check for body structure
    if (!body || !body.data) {
      console.log('⚠️ Webhook body invalid or missing data');
      res.status(200).send('Ignored');
      return;
    }

    // Accept both 'messages.upsert' and 'messages.received'
    if (body.event !== 'messages.upsert' && body.event !== 'messages.received') {
      console.log(`ℹ️ Ignoring event type: ${body.event}`);
      res.status(200).send('Ignored');
      return;
    }

    // Handle different data structures
    // Some events have data.messages, others might be direct
    const messageData = body.data.messages || body.data;

    // WeSander often sends specific keys like 'message' inside the structure
    // Log for clarity
    console.log('🔍 Processing Message Data:', JSON.stringify(messageData, null, 2));

    const remoteJid = messageData.key?.remoteJid || messageData.from || messageData.remoteJid;

    const phone = messageData.key?.cleanedSenderPn ||
      (messageData.key?.senderPn ? messageData.key.senderPn.split('@')[0] : null) ||
      messageData.cleanedSenderPn ||
      (messageData.senderPn ? messageData.senderPn.split('@')[0] : null) ||
      (remoteJid ? remoteJid.split('@')[0] : null);

    const messageText = messageData.messageBody ||
      messageData.message?.conversation ||
      messageData.message?.extendedTextMessage?.text ||
      messageData.body;

    const senderName = messageData.pushName || messageData.verifiedBizName || 'Unknown User';
    const isFromMe = messageData.key?.fromMe || false;

    if (isFromMe) {
      res.status(200).send('Ignored');
      return;
    }

    if (!phone || !messageText) {
      res.status(200).send('Missing Data');
      return;
    }

    console.log(`📨 New Message from ${senderName} (${phone}): ${messageText}`);

    const conversationRef = admin.firestore().collection('whatsapp_conversations').doc(phone);
    const messagesRef = conversationRef.collection('messages');

    await admin.firestore().runTransaction(async (t) => {
      const conversationDoc = await t.get(conversationRef);

      if (!conversationDoc.exists) {
        t.set(conversationRef, {
          phoneNumber: phone,
          userName: senderName,
          lastMessage: messageText,
          lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
          unreadCount: 1,
          ai_active: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
      } else {
        t.update(conversationRef, {
          lastMessage: messageText,
          lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
          unreadCount: admin.firestore.FieldValue.increment(1),
          userName: senderName
        });
      }

      const newMessageRef = messagesRef.doc();
      t.set(newMessageRef, {
        text: messageText,
        isFromUser: true,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        wesanderId: messageData.key?.id || null
      });
    });

    res.status(200).send('Processed');

  } catch (error) {
    console.error('❌ Webhook error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// 2. AI Auto-Reply Bot (Firestore Trigger v2)
exports.whatsappAutoReply = onDocumentCreatedV2("whatsapp_conversations/{phone}/messages/{messageId}", async (event) => {
  const snap = event.data;
  if (!snap) return; // Deleted?

  const messageData = snap.data();
  const phone = event.params.phone;

  if (!messageData.isFromUser) return;

  console.log(`🤖 Checking Auto-Reply for ${phone}...`);

  try {
    const chatDoc = await admin.firestore().collection('whatsapp_conversations').doc(phone).get();
    if (!chatDoc.exists || !chatDoc.data().ai_active) {
      console.log('🔕 AI is DISABLED for this chat.');
      return;
    }

    const settingsDoc = await admin.firestore().collection('system_settings').doc('whatsapp_bot').get();
    const systemPrompt = settingsDoc.exists ? settingsDoc.data().prompt :
      "You are the Formal Personal Assistant (PA) for Colane Ngobese, the founder of Impact Graphics ZA, GigLinkSA, and technical operator for several ventures including MwelaseFin and Faithbase. " +
      "Tone: Highly professional, formal, and respectful. Use clear and grammatically correct language. " +
      "1. Formally introduce yourself as Colane's Personal Assistant and explicitly state that Colane is currently unavailable. " +
      "2. Inform the user that you will be taking over the chat to assist them in the meantime, and that you will provide Colane with a complete briefing of the conversation later. " +
      "3. Assist the user with professional inquiries regarding design, branding, websites, or business operations using Colane's established knowledge base. " +
      "4. Maintain a polite and helpful demeanor throughout the interaction. " +
      "5. If a message is received in a language you cannot process, formally request the user to communicate in English for better assistance. " +
      "6. Ensure all responses are structured professionally and avoid informal expressions or overly casual tone.";


    const historySnap = await admin.firestore()
      .collection('whatsapp_conversations')
      .doc(phone)
      .collection('messages')
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();

    const history = historySnap.docs.map(doc => ({
      role: doc.data().isFromUser ? 'user' : 'assistant',
      content: doc.data().text
    })).reverse();

    console.log('🧠 Calling OpenRouter AI (Trinity Large Preview)...');
    let replyText = "I'm sorry, I'm having trouble connecting right now.";

    const secrets = await getSecrets();
    const openrouterKey = secrets.openrouter_key;

    if (!openrouterKey) {
      console.error('❌ OpenRouter API Key missing in secrets.');
      return;
    }

    try {
      const aiResponse = await axios.post(
        'https://openrouter.ai/api/v1/chat/completions',
        {
          model: 'arcee-ai/trinity-large-preview:free',
          messages: [
            { role: 'system', content: systemPrompt },
            ...history
          ]
        },
        {
          headers: {
            'Authorization': `Bearer ${openrouterKey}`,
            'HTTP-Referer': YOUR_SITE_URL,
            'X-Title': YOUR_SITE_NAME,
            'Content-Type': 'application/json'
          }
        }
      );
      replyText = aiResponse.data.choices[0].message.content;
    } catch (aiError) {
      console.error('OpenRouter Error:', aiError.response?.data || aiError.message);
      return;
    }

    console.log(`💡 AI Reply: ${replyText}`);

    // Send via WeSander
    const wesanderKey = secrets.wesander_key || secrets.wesander_api_key;

    if (wesanderKey) {
      // Resolve real phone number handles LID cases
      const conversationDoc = await admin.firestore().collection('whatsapp_conversations').doc(phone).get();
      let targetPhone = phone;

      if (conversationDoc.exists && conversationDoc.data().phoneNumber) {
        targetPhone = conversationDoc.data().phoneNumber;
      }

      // Sanitize: Remove +, spaces, and non-numeric chars
      targetPhone = targetPhone.replace(/\D/g, '');

      // Ensure proper JID format (Country code 27 fallback if missing is optional but safe to assume provided full)
      const formattedPhone = targetPhone.includes('@') ? targetPhone : `${targetPhone}@s.whatsapp.net`;

      await axios.post('https://wasenderapi.com/api/send-message', {
        to: formattedPhone,
        text: replyText
      }, {
        headers: { 'Authorization': `Bearer ${wesanderKey}` }
      });
      console.log('📤 Message sent via WeSander');
    } else {
      console.log('⚠️ WeSander Key missing. Reply stored but NOT sent.');
    }

    // Save Bot Reply
    await admin.firestore()
      .collection('whatsapp_conversations')
      .doc(phone)
      .collection('messages')
      .add({
        text: replyText,
        isFromUser: false,
        isAi: true,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

  } catch (error) {
    console.error('❌ Auto-Reply Error:', error);
  }
});

// 4. Cleanup Corrupt Chats (Temporary Utility)
exports.cleanupCorruptChats = onRequest(async (req, res) => {

  exports.sendWhatsAppMessage = onCallV2(async (request) => {
    // v2: request.auth, request.data
    if (!request.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    const { phone, message } = request.data;

    if (!phone || !message) {
      throw new functions.https.HttpsError('invalid-argument', 'Phone and message are required.');
    }

    try {
      const secrets = await getSecrets();
      const wesanderKey = secrets.wesander_key || secrets.wesander_api_key;

      if (!wesanderKey) {
        throw new functions.https.HttpsError('failed-precondition', 'WeSander API Key not configured.');
      }

      // Resolve real phone number from Firestore (handles LID cases)
      const conversationDoc = await admin.firestore().collection('whatsapp_conversations').doc(phone).get();
      let targetPhone = phone;

      if (conversationDoc.exists && conversationDoc.data().phoneNumber) {
        targetPhone = conversationDoc.data().phoneNumber;
      }

      // Sanitize: Remove +, spaces, and non-numeric chars
      targetPhone = targetPhone.replace(/\D/g, '');

      // Ensure proper JID format
      const formattedPhone = targetPhone.includes('@') ? targetPhone : `${targetPhone}@s.whatsapp.net`;

      await axios.post('https://wasenderapi.com/api/send-message', {
        to: formattedPhone,
        text: message
      }, {
        headers: { 'Authorization': `Bearer ${wesanderKey}` }
      });

      await admin.firestore()
        .collection('whatsapp_conversations')
        .doc(phone)
        .collection('messages')
        .add({
          text: message,
          isFromUser: false,
          isAi: false,
          isManuallySent: true,
          adminId: request.auth.uid,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

      await admin.firestore().collection('whatsapp_conversations').doc(phone).update({
        lastMessage: message,
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true };

    } catch (error) {
      console.error('❌ Send Message Error:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });