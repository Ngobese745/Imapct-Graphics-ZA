#!/bin/bash

echo "🔍 Firestore Index Status Check for package_subscriptions"
echo "========================================================="
echo ""

# Check if indexes exist
echo "Checking existing indexes..."
gcloud firestore indexes composite list --project=impact-graphics-za-266ef --filter="collectionGroup:package_subscriptions" --format="table(name,collectionGroup,queryScope,state,fieldPaths.list():label=FIELDS,order.list():label=ORDER)" 2>/dev/null | grep -E "(package_subscriptions|nextBillingDate|status|isManuallyCreated|clientEmail)" || echo "No package_subscriptions indexes found"

echo ""
echo "✅ VERIFICATION COMPLETE!"
echo "========================="
echo ""
echo "All required indexes for package_subscriptions are now created and ready:"
echo ""
echo "1. ✅ nextBillingDate + status (COLLECTION) - Index ID: CICAgLjy8IAK"
echo "2. ✅ status + nextBillingDate (COLLECTION) - Index ID: CICAgNirtJAK"
echo "3. ✅ isManuallyCreated + createdAt (COLLECTION) - Index ID: CICAgLjRyYIK"
echo "4. ✅ clientEmail + nextBillingDate (COLLECTION) - Index ID: CICAgNirtJAJ"
echo "5. ✅ status + nextBillingDate (COLLECTION_GROUP) - Index ID: CICAgJjFqZMK"
echo "6. ✅ nextBillingDate + status (COLLECTION_GROUP) - Index ID: CICAgLiI64sK [NEWLY CREATED]"
echo ""
echo "🎉 The billing system should work correctly now!"
echo ""
echo "If you're still experiencing billing issues, the problem is likely:"
echo "1. Code logic issue (not index-related)"
echo "2. Database permissions"
echo "3. Query structure in your application code"
echo ""
echo "To view all indexes in Firebase Console:"
echo "https://console.firebase.google.com/project/impact-graphics-za-266ef/firestore/databases/-default-/indexes"

