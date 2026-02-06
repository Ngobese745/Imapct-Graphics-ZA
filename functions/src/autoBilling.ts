import { format } from 'date-fns';
import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

/**
 * Automated Billing Cloud Function
 * Runs daily to check for packages due for billing and send invoice emails
 */
export const autoBilling = functions.pubsub
    .schedule('0 9 * * *') // Run daily at 9:00 AM UTC (11:00 AM SAST)
    .timeZone('Africa/Johannesburg')
    .onRun(async (context) => {
        console.log('🔄 Starting automated billing process...');

        try {
            // Get today's date in South Africa timezone
            const today = new Date();
            const todayStr = format(today, 'yyyy-MM-dd');
            console.log(`📅 Checking for packages due on: ${todayStr}`);

            // Query packages due for billing today
            const packagesQuery = db.collection('package_subscriptions')
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

                    // Send invoice email using the existing service
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
                        // Update next billing date
                        const nextBillingDate = calculateNextBillingDate(
                            packageData.nextBillingDate.toDate(),
                            packageData.billingCycle
                        );

                        await doc.ref.update({
                            nextBillingDate: admin.firestore.Timestamp.fromDate(nextBillingDate),
                            lastBillingDate: admin.firestore.Timestamp.fromDate(today),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        });

                        console.log(`✅ Invoice sent successfully for ${packageData.clientName}`);
                        console.log(`📅 Next billing date updated to: ${format(nextBillingDate, 'yyyy-MM-dd')}`);

                        billingResults.push({
                            packageId,
                            clientName: packageData.clientName,
                            clientEmail: packageData.clientEmail,
                            success: true,
                            nextBillingDate: format(nextBillingDate, 'yyyy-MM-dd'),
                        });
                    } else {
                        console.error(`❌ Failed to send invoice for ${packageData.clientName}: ${emailResult.message}`);

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

            // Log summary
            const successful = billingResults.filter(r => r.success).length;
            const failed = billingResults.filter(r => !r.success).length;

            console.log(`📊 Billing Summary:`);
            console.log(`✅ Successful: ${successful}`);
            console.log(`❌ Failed: ${failed}`);
            console.log(`📦 Total Processed: ${billingResults.length}`);

            // Store billing results for admin review
            await db.collection('billing_logs').add({
                date: todayStr,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                totalPackages: billingResults.length,
                successful,
                failed,
                results: billingResults,
            });

            console.log('✅ Automated billing process completed');

            return {
                success: true,
                totalPackages: billingResults.length,
                successful,
                failed,
            };

        } catch (error) {
            console.error('❌ Automated billing process failed:', error);

            // Log error
            await db.collection('billing_logs').add({
                date: format(new Date(), 'yyyy-MM-dd'),
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                error: error.message,
                success: false,
            });

            throw error;
        }
    });

/**
 * Calculate the next billing date based on billing cycle
 */
function calculateNextBillingDate(currentDate: Date, billingCycle: string): Date {
    const nextDate = new Date(currentDate);

    switch (billingCycle.toLowerCase()) {
        case 'monthly':
            nextDate.setMonth(nextDate.getMonth() + 1);
            break;
        case 'quarterly':
            nextDate.setMonth(nextDate.getMonth() + 3);
            break;
        case 'yearly':
        case 'annual':
            nextDate.setFullYear(nextDate.getFullYear() + 1);
            break;
        case 'weekly':
            nextDate.setDate(nextDate.getDate() + 7);
            break;
        default:
            // Default to monthly
            nextDate.setMonth(nextDate.getMonth() + 1);
            break;
    }

    return nextDate;
}

/**
 * Send automated invoice email using the existing email service structure
 */
async function sendAutoInvoiceEmail({
    clientName,
    clientEmail,
    packageName,
    packagePrice,
    billingCycle,
    nextBillingDate,
    packageId,
}: {
    clientName: string;
    clientEmail: string;
    packageName: string;
    packagePrice: number;
    billingCycle: string;
    nextBillingDate: Date;
    packageId: string;
}): Promise<{ success: boolean; message: string; messageId?: string }> {
    try {
        console.log('📧 Preparing automated invoice email...');

        // Calculate amount in Rand for Paystack
        const amountInRand = Math.round(packagePrice);
        const baseUrl = 'https://paystack.shop/pay/n6c6hp792r';
        const paymentLink = `${baseUrl}?amount=${amountInRand}&email=${encodeURIComponent(clientEmail)}&name=${encodeURIComponent(clientName)}`;

        console.log(`🔗 Generated payment link: ${paymentLink}`);

        // Format dates and prices
        const formattedPrice = `R ${packagePrice.toFixed(2)}`;
        const formattedDate = format(nextBillingDate, 'MMMM dd, yyyy');
        const invoiceNumber = `PKG-${packageId.substring(0, 8).toUpperCase()}`;

        // Build email template (same as the enhanced template)
        const emailBody = buildAutoInvoiceEmailTemplate({
            clientName,
            packageName,
            packagePrice: formattedPrice,
            billingCycle,
            nextBillingDate: formattedDate,
            invoiceNumber,
            paymentLink,
        });

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
        const docRef = await db.collection('emails').add(emailData);

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
            message: `Error sending automated invoice email: ${error.message}`,
        };
    }
}

/**
 * Build the automated invoice email template (same as manual template)
 */
function buildAutoInvoiceEmailTemplate({
    clientName,
    packageName,
    packagePrice,
    billingCycle,
    nextBillingDate,
    invoiceNumber,
    paymentLink,
}: {
    clientName: string;
    packageName: string;
    packagePrice: string;
    billingCycle: string;
    nextBillingDate: string;
    invoiceNumber: string;
    paymentLink: string;
}): string {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Monthly Invoice - Impact Graphics ZA</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap');
  </style>
</head>
<body style="margin: 0; padding: 0; font-family: 'Poppins', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 30px 0;">
    <tr>
      <td align="center">
        <table width="650" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.15);">
          
          <!-- Header with Logo -->
          <tr>
            <td style="background: linear-gradient(135deg, #8B0000 0%, #6B0000 50%, #4B0000 100%); padding: 50px 40px; text-align: center; position: relative;">
              <!-- Logo -->
              <div style="margin-bottom: 20px;">
                <img src="https://impactgraphicsza.co.za/assets/logo.png" 
                     alt="Impact Graphics ZA Logo" 
                     style="max-width: 180px; height: auto; filter: brightness(0) invert(1);" 
                     onerror="this.style.display='none'">
              </div>
              <h1 style="color: #ffffff; margin: 0; font-size: 32px; font-weight: 700; letter-spacing: 1px; text-transform: uppercase;">IMPACT GRAPHICS ZA</h1>
              <div style="width: 60px; height: 3px; background-color: #ffffff; margin: 15px auto;"></div>
              <p style="color: #ffffff; margin: 10px 0 0 0; font-size: 16px; opacity: 0.95; font-weight: 600;">MONTHLY INVOICE</p>
            </td>
          </tr>

          <!-- Greeting Section -->
          <tr>
            <td style="padding: 40px 40px 20px 40px;">
              <h2 style="color: #333; margin: 0 0 15px 0; font-size: 24px; font-weight: 600;">Hello ${clientName},</h2>
              <p style="color: #666; margin: 0; font-size: 15px; line-height: 1.6;">Your monthly invoice for your subscription package is ready. Please find the details below.</p>
            </td>
          </tr>

          <!-- Invoice Info -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8f8f8; border-radius: 8px; padding: 20px; border-left: 4px solid #8B0000;">
                <tr>
                  <td>
                    <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Invoice To</p>
                    <p style="margin: 8px 0 0 0; color: #333; font-size: 18px; font-weight: 600;">${clientName}</p>
                  </td>
                  <td align="right">
                    <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Invoice #</p>
                    <p style="margin: 8px 0 0 0; color: #8B0000; font-size: 18px; font-weight: 700;">${invoiceNumber}</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Package Details -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #f8f8f8 0%, #ffffff 100%); border-radius: 12px; border: 2px solid #e0e0e0; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #8B0000 0%, #6B0000 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 18px; font-weight: 600; letter-spacing: 0.5px;">📦 PACKAGE DETAILS</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 20px;">
                  <tr>
                    <td style="padding: 12px 0; border-bottom: 1px solid #e0e0e0;">
                      <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Package Name</p>
                      <p style="margin: 6px 0 0 0; color: #333; font-size: 16px; font-weight: 600;">${packageName}</p>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 12px 0; border-bottom: 1px solid #e0e0e0;">
                      <table width="100%" cellpadding="0" cellspacing="0">
                        <tr>
                          <td>
                            <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Billing Cycle</p>
                            <p style="margin: 6px 0 0 0; color: #333; font-size: 15px; font-weight: 600;">${billingCycle.charAt(0).toUpperCase() + billingCycle.slice(1)}</p>
                          </td>
                          <td align="right">
                            <p style="margin: 0; color: #999; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Next Billing</p>
                            <p style="margin: 6px 0 0 0; color: #333; font-size: 15px; font-weight: 600;">${nextBillingDate}</p>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                  <tr>
                    <td style="padding: 20px 0 0 0;">
                      <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #8B0000 0%, #6B0000 100%); border-radius: 8px; padding: 20px;">
                        <tr>
                          <td>
                            <p style="margin: 0; color: #ffffff; font-size: 14px; opacity: 0.9; text-transform: uppercase; letter-spacing: 1px;">Total Amount Due</p>
                          </td>
                          <td align="right">
                            <p style="margin: 0; color: #ffffff; font-size: 24px; font-weight: 700; letter-spacing: 1px;">${packagePrice}</p>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Payment Button -->
          <tr>
            <td style="padding: 20px 40px 30px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #f0f0f0 0%, #ffffff 100%); border-radius: 12px; padding: 30px; text-align: center;">
                <tr>
                  <td>
                    <p style="margin: 0 0 20px 0; color: #333; font-size: 16px; font-weight: 600;">Ready to complete your payment?</p>
                    <a href="${paymentLink}" 
                       style="display: inline-block; 
                              background: linear-gradient(135deg, #8B0000 0%, #6B0000 100%); 
                              color: #ffffff; 
                              text-decoration: none; 
                              padding: 18px 60px; 
                              border-radius: 50px; 
                              font-size: 18px; 
                              font-weight: 700; 
                              letter-spacing: 1px;
                              text-transform: uppercase;
                              box-shadow: 0 6px 20px rgba(139,0,0,0.4);
                              transition: all 0.3s ease;">
                      💳 PAY NOW
                    </a>
                    <p style="margin: 20px 0 0 0; color: #999; font-size: 13px; line-height: 1.6;">
                      Click the button above to make your payment securely via Paystack<br>
                      <span style="color: #8B0000; font-weight: 600;">🔒 Secured by Paystack</span>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Alternative Payment Methods -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%); border-radius: 12px; border: 2px solid #e9ecef; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #28a745 0%, #20c997 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">🏦 ALTERNATIVE PAYMENT METHODS</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <p style="margin: 0 0 15px 0; color: #333; font-size: 14px; font-weight: 600;">Prefer Bank Transfer?</p>
                      <div style="background-color: #ffffff; border-radius: 8px; padding: 20px; border-left: 4px solid #28a745;">
                        <table width="100%" cellpadding="0" cellspacing="0">
                          <tr>
                            <td style="padding: 8px 0;">
                              <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Bank Name</span><br>
                              <span style="color: #333; font-size: 15px; font-weight: 600;">Capitec Business</span>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding: 8px 0;">
                              <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Account Number</span><br>
                              <span style="color: #333; font-size: 18px; font-weight: 700; letter-spacing: 2px;">1053262485</span>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding: 8px 0;">
                              <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Account Holder</span><br>
                              <span style="color: #333; font-size: 15px; font-weight: 600;">Impact Graphics ZA</span>
                            </td>
                          </tr>
                          <tr>
                            <td style="padding: 8px 0;">
                              <span style="color: #666; font-size: 12px; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Reference</span><br>
                              <span style="color: #8B0000; font-size: 15px; font-weight: 700;">${invoiceNumber}</span>
                            </td>
                          </tr>
                        </table>
                      </div>
                      <p style="margin: 15px 0 0 0; color: #666; font-size: 12px; line-height: 1.6;">
                        💡 <strong>Important:</strong> Please use the invoice number as your payment reference when making a bank transfer.
                      </p>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Important Notice -->
          <tr>
            <td style="padding: 0 40px 30px 40px;">
              <div style="background: linear-gradient(135deg, #fff8e1 0%, #fffbf0 100%); border-radius: 12px; border: 2px solid #ffd54f; overflow: hidden;">
                <div style="background: linear-gradient(90deg, #ff9800 0%, #ff5722 100%); padding: 15px 20px;">
                  <h2 style="margin: 0; color: #ffffff; font-size: 16px; font-weight: 600; letter-spacing: 0.5px;">💡 IMPORTANT NOTICE</h2>
                </div>
                <table width="100%" cellpadding="0" cellspacing="0" style="padding: 25px;">
                  <tr>
                    <td>
                      <p style="margin: 0 0 15px 0; color: #e65100; font-size: 14px; line-height: 1.8; font-weight: 600;">
                        This is your automated monthly invoice. If you have <strong>already paid</strong> for this month, you can safely <strong>ignore this email</strong>.
                      </p>
                      <p style="margin: 0; color: #e65100; font-size: 14px; line-height: 1.8;">
                        Our records will be updated automatically upon payment confirmation. For bank transfers, please ensure you use the invoice number as your payment reference.
                      </p>
                    </td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>

          <!-- Contact Section -->
          <tr>
            <td style="padding: 0 40px 40px 40px;">
              <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f8f8f8; border-radius: 12px; padding: 25px; text-align: center;">
                <tr>
                  <td>
                    <p style="margin: 0 0 15px 0; color: #333; font-size: 16px; font-weight: 600;">Need Help?</p>
                    <p style="margin: 0; color: #666; font-size: 14px; line-height: 1.6;">
                      Have questions about your invoice or billing?<br>
                      We're here to help!
                    </p>
                    <div style="margin-top: 20px;">
                      <a href="mailto:info@impactgraphicsza.co.za" 
                         style="display: inline-block; 
                                color: #8B0000; 
                                text-decoration: none; 
                                font-weight: 600; 
                                font-size: 15px;
                                padding: 12px 30px;
                                background-color: #ffffff;
                                border: 2px solid #8B0000;
                                border-radius: 6px;
                                transition: all 0.3s ease;">
                        📧 Contact Support
                      </a>
                    </div>
                    <p style="margin: 15px 0 0 0; color: #999; font-size: 13px;">
                      Email: info@impactgraphicsza.co.za<br>
                      WhatsApp: +27 68 367 5755
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background: linear-gradient(135deg, #2a2a2a 0%, #1a1a1a 100%); padding: 30px; text-align: center;">
              <div style="margin-bottom: 15px;">
                <img src="https://impactgraphicsza.co.za/assets/logo.png" 
                     alt="Impact Graphics ZA" 
                     style="max-width: 120px; height: auto; opacity: 0.6; filter: brightness(0) invert(1);" 
                     onerror="this.style.display='none'">
              </div>
              <p style="margin: 0 0 10px 0; color: #ffffff; font-size: 16px; font-weight: 600;">IMPACT GRAPHICS ZA</p>
              <p style="margin: 0 0 15px 0; color: #999; font-size: 12px; line-height: 1.6;">
                Professional Graphic Design & Marketing Solutions<br>
                Making Your Brand Stand Out
              </p>
              <div style="margin: 20px 0;">
                <a href="https://impact-graphics-za-266ef.web.app" style="color: #8B0000; text-decoration: none; font-weight: 600; font-size: 13px; margin: 0 10px;">🌐 Visit Website</a>
                <span style="color: #666;">•</span>
                <a href="https://www.facebook.com/impactgraphicsza" style="color: #8B0000; text-decoration: none; font-weight: 600; font-size: 13px; margin: 0 10px;">📱 Facebook</a>
                <span style="color: #666;">•</span>
                <a href="https://www.instagram.com/impactgraphicsza" style="color: #8B0000; text-decoration: none; font-weight: 600; font-size: 13px; margin: 0 10px;">📸 Instagram</a>
              </div>
              <div style="border-top: 1px solid #444; margin: 20px 0; padding-top: 20px;">
                <p style="margin: 0; color: #888; font-size: 11px; line-height: 1.6;">
                  © ${new Date().getFullYear()} Impact Graphics ZA. All rights reserved.<br>
                  This is an automated invoice email. Please do not reply to this message.<br>
                  For support, contact us at info@impactgraphicsza.co.za
                </p>
              </div>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;
}



