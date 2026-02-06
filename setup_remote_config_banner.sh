#!/bin/bash

# Setup Remote Config Banner Parameters for Firebase
# This script provides the exact parameters to add to Firebase Remote Config

echo "======================================================"
echo "Firebase Remote Config - Development Banner Setup"
echo "======================================================"
echo ""
echo "Follow these steps to add the banner parameters:"
echo ""
echo "1. Open Firebase Console:"
echo "   https://console.firebase.google.com/project/impact-graphics-za-266ef/config"
echo ""
echo "2. Click 'Add parameter' button"
echo ""
echo "3. Add each of the following parameters:"
echo ""
echo "------------------------------------------------------"
echo "Parameter 1: Banner Visibility"
echo "------------------------------------------------------"
echo "Parameter key: show_development_banner"
echo "Data type: Boolean"
echo "Default value: true"
echo "Description: Toggle to show/hide the development banner"
echo ""
echo "------------------------------------------------------"
echo "Parameter 2: Banner Title"
echo "------------------------------------------------------"
echo "Parameter key: development_banner_title"
echo "Data type: String"
echo "Default value: 🚧 App Under Development"
echo "Description: The title text displayed in the banner"
echo ""
echo "------------------------------------------------------"
echo "Parameter 3: Banner Message"
echo "------------------------------------------------------"
echo "Parameter key: development_banner_message"
echo "Data type: String"
echo "Default value: We're still working on improving your experience! Report any issues or suggestions via the menu."
echo "Description: The message text displayed in the banner"
echo ""
echo "------------------------------------------------------"
echo "Parameter 4: Banner Background Color"
echo "------------------------------------------------------"
echo "Parameter key: development_banner_color"
echo "Data type: String"
echo "Default value: #FF6B35"
echo "Description: Background color of the banner (hex format)"
echo ""
echo "------------------------------------------------------"
echo "Parameter 5: Banner Text Color"
echo "------------------------------------------------------"
echo "Parameter key: development_banner_text_color"
echo "Data type: String"
echo "Default value: #FFFFFF"
echo "Description: Text color of the banner (hex format)"
echo ""
echo "------------------------------------------------------"
echo ""
echo "4. After adding all parameters, click 'Publish changes'"
echo ""
echo "5. The banner will update in the app within 1 hour"
echo "   (or immediately on app restart)"
echo ""
echo "======================================================"
echo "Alternative Color Suggestions:"
echo "======================================================"
echo ""
echo "Orange (Current):  #FF6B35"
echo "Red (Alert):       #8B0000"
echo "Blue (Info):       #1976D2"
echo "Green (Success):   #388E3C"
echo "Purple (Premium):  #7B1FA2"
echo "Yellow (Warning):  #FFA000"
echo ""
echo "======================================================"
echo "Quick Test Commands:"
echo "======================================================"
echo ""
echo "To test different configurations, update these values"
echo "in Firebase Console and click 'Publish changes'"
echo ""
echo "Example 1: Hide banner completely"
echo "  show_development_banner: false"
echo ""
echo "Example 2: Change to red alert banner"
echo "  development_banner_color: #8B0000"
echo "  development_banner_title: ⚠️ Beta Version"
echo ""
echo "Example 3: Change to blue info banner"
echo "  development_banner_color: #1976D2"
echo "  development_banner_title: ℹ️ New Features Available"
echo ""
echo "======================================================"
echo ""

# Save configuration to JSON file for reference
cat > remote_config_banner_template.json << 'EOF'
{
  "parameters": {
    "show_development_banner": {
      "defaultValue": {
        "value": "true"
      },
      "description": "Toggle to show/hide the development banner",
      "valueType": "BOOLEAN"
    },
    "development_banner_title": {
      "defaultValue": {
        "value": "🚧 App Under Development"
      },
      "description": "The title text displayed in the banner",
      "valueType": "STRING"
    },
    "development_banner_message": {
      "defaultValue": {
        "value": "We're still working on improving your experience! Report any issues or suggestions via the menu."
      },
      "description": "The message text displayed in the banner",
      "valueType": "STRING"
    },
    "development_banner_color": {
      "defaultValue": {
        "value": "#FF6B35"
      },
      "description": "Background color of the banner (hex format)",
      "valueType": "STRING"
    },
    "development_banner_text_color": {
      "defaultValue": {
        "value": "#FFFFFF"
      },
      "description": "Text color of the banner (hex format)",
      "valueType": "STRING"
    }
  }
}
EOF

echo "✅ Configuration template saved to: remote_config_banner_template.json"
echo ""
echo "You can use this JSON file as a reference when adding"
echo "parameters manually in the Firebase Console."
echo ""
echo "======================================================"
echo "Documentation:"
echo "======================================================"
echo ""
echo "For more details, see:"
echo "  - DEVELOPMENT_BANNER_FEATURE_COMPLETE.md"
echo "  - FIREBASE_REMOTE_CONFIG_SETUP.md"
echo ""
echo "======================================================"



