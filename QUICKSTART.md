# Collabora Online Plugin - Quick Start Guide

## What Was Created

A complete Redmine plugin (`redmine_collabora_online`) that integrates Collabora Online server with your Redmine installation, enabling users to view and edit office documents directly within Redmine.

## Plugin Location

```
/var/www/redmine/plugins/redmine_collabora_online/
```

## What the Plugin Does

1. **Detects Office Documents** - Automatically identifies Microsoft Office and OpenDocument formats
2. **Adds View/Edit Buttons** - Displays buttons next to office attachments
3. **Manages Permissions** - Controls access based on Redmine user permissions
4. **Embeds Collabora Online** - Opens documents in Collabora Online within an iframe
5. **Provides WOPI Support** - Implements Web Open Platform Interface for secure access

## Supported Document Formats

✅ **Microsoft Office:**
- Word: .docx, .doc, .docm, .dotx, .dot, .dotm
- Excel: .xlsx, .xls, .xlsm, .xltx, .xlt, .xltm
- PowerPoint: .pptx, .ppt, .pptm, .potx, .pot, .potm

✅ **LibreOffice/OpenDocument:**
- Writer: .odt, .ott
- Calc: .ods, .ots
- Impress: .odp, .otp

✅ **Other:**
- Text: .rtf, .txt, .csv

## Next Steps

### 1. Restart Redmine (Required)
The plugin will load on restart:
```bash
sudo systemctl restart redmine
```

Or if using manual startup, restart your application server.

### 2. Configure Collabora Server URL (Required)
1. Log in to Redmine as Administrator
2. Go to **Administration** → **Plugins**
3. Find "Redmine Collabora Online" in the plugin list
4. Click the **Configure** button (⚙️ icon)
5. Enter your Collabora Online server URL:
   ```
   https://office.myco.co.za
   ```
6. Ensure "Enable Collabora Online" checkbox is checked
7. Click **Save**

### 3. Test the Plugin
1. Create or find an Issue with an attached Word or Excel file
2. View the attachment - you should see "View in Collabora" and "Edit in Collabora" buttons
3. Click "View in Collabora" to open the document

## Plugin Features

### For Users
- ✅ View office documents without downloading
- ✅ Edit documents with full formatting
- ✅ Real-time collaboration (if Collabora configured for it)
- ✅ Permission-based access control
- ✅ Inline document editing

### For Admins
- ✅ Simple configuration (just the server URL)
- ✅ Permission-based security
- ✅ Plugin can be enabled/disabled
- ✅ No database migrations required
- ✅ No additional dependencies

## Architecture Overview

```
User Attachment Request
        ↓
Redmine Attachment Display
        ↓
Plugin Hook (view_attachment_file_links)
        ↓
Checks: Is Office Document? Is Plugin Enabled? Does User Have Permission?
        ↓
YES → Display "View" and "Edit" buttons
NO  → Skip Collabora buttons
        ↓
User Clicks Button
        ↓
CollaboraOnlineController
        ↓
Validates Permissions
        ↓
Generates WOPI URL with Access Token
        ↓
Embeds Collabora Online iframe
        ↓
Opens Document in Editor
```

## Security Features

1. **Authentication Required** - Only logged-in users can access
2. **Permission-Based Access** - Respects Redmine permissions
3. **WOPI Tokens** - Secure, time-limited access tokens
4. **HTTPS Only** - All communication encrypted
5. **Token Expiration** - Tokens expire after 1 hour

## File Structure

```
redmine_collabora_online/
├── app/
│   ├── controllers/
│   │   └── collabora_online_controller.rb    # Main controller
│   ├── assets/
│   │   ├── stylesheets/
│   │   │   └── collabora_online.css
│   │   ├── javascripts/
│   │   │   └── collabora_online.js
│   │   └── images/
│   │       ├── collabora_view.svg
│   │       └── collabora_edit.svg
│   └── views/
│       ├── collabora_online/
│       │   ├── view.html.erb       # View mode
│       │   └── edit.html.erb       # Edit mode
│       └── settings/
│           └── _collabora_online.html.erb  # Admin settings
├── lib/
│   ├── redmine_collabora_online.rb           # Main module
│   └── redmine_collabora_online/
│       ├── document_helper.rb               # Document type detection
│       ├── wopi_helper.rb                   # WOPI URL generation
│       ├── attachment_hook.rb               # UI hooks
│       └── attachment_helper_patch.rb       # Helper extensions
├── config/
│   ├── routes.rb                     # URL routes
│   └── locales/
│       ├── en.yml                    # English translations
│       └── de.yml                    # German translations
└── init.rb                           # Plugin initialization
```

## Success Indicators

✅ Plugin appears in Admin → Plugins list
✅ Configure button is clickable
✅ Settings page shows URL field
✅ Collabora buttons appear on office attachments
✅ Documents open in Collabora iframe
✅ Editing works and saves correctly

You're all set! The plugin is ready to use.
