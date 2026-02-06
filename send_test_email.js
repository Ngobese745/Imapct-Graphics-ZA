const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp({
    projectId: 'impact-graphics-za-266ef'
});

const db = admin.firestore();

// Test email data
const testEmail = {
    to: [
        {
            email: "colane.comfort.5@gmail.com",
            name: "Colane Comfort"
        }
    ],
    subject: "✅ Email System Fixed - Test Email",
    html: `<h1>🎉 Email System Working!</h1>
<p>This test email confirms that the MailerSend API key has been successfully updated and the email system is now working again.</p>
<p><strong>✅ New API Key:</strong> mlsn.67a87f****** (Impact token)</p>
<p><strong>✅ Status:</strong> ACTIVE</p>
<p><strong>✅ Domain:</strong> impactgraphicsza.co.za</p>
<p><strong>✅ Extension:</strong> mailersend/mailersend-email@0.1.8</p>
<p><strong>📅 Fixed:</strong> October 20, 2025</p>
<hr>
<p>If you receive this email, the email system is fully restored and ready for production use!</p>`,
    text: `🎉 Email System Working!

This test email confirms that the MailerSend API key has been successfully updated and the email system is now working again.

✅ New API Key: mlsn.67a87f****** (Impact token)
✅ Status: ACTIVE
✅ Domain: impactgraphicsza.co.za
✅ Extension: mailersend/mailersend-email@0.1.8
📅 Fixed: October 20, 2025

If you receive this email, the email system is fully restored and ready for production use!`,
    tags: ["test", "api-key-fix", "email-system-restored"],
    created_at: new Date().toISOString()
};

// Add the test email to Firestore
db.collection('emails').add(testEmail)
    .then(doc => {
        console.log('✅ Test email document created with ID:', doc.id);
        console.log('📧 Email will be sent to:', testEmail.to[0].email);
        console.log('📝 Subject:', testEmail.subject);
        console.log('🕐 Created at:', testEmail.created_at);
        console.log('');
        console.log('🔍 Monitor the document in Firebase Console:');
        console.log('https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/data/~2Femails~2F' + doc.id);
        console.log('');
        console.log('📊 Check logs with:');
        console.log('firebase functions:log --project=impact-graphics-za-266ef | grep -i mailersend');
        process.exit(0);
    })
    .catch(error => {
        console.error('❌ Error creating test email:', error);
        process.exit(1);
    });


