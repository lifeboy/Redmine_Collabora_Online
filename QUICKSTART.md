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
   https://office.abellardss.co.za
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

## Troubleshooting

### Plugin Not Showing in Administration
- Restart Redmine: `sudo systemctl restart redmine`
- Check plugin directory: `/var/www/redmine/plugins/redmine_collabora_online/`
- Verify init.rb exists and is readable

### Buttons Not Appearing on Attachments
1. Check plugin is enabled in Admin → Plugins
2. Verify Collabora URL is configured
3. Make sure the file format is supported (see list above)
4. Check user has permission to view the container

### "Collabora Online is not configured" Error
- Go to Admin → Plugins → Configure Collabora Online
- Enter the server URL: `https://office.abellardss.co.za`
- Click Save

### Document Won't Open in Editor
- Verify you have edit permission for the issue/project
- Check Collabora server is accessible (HTTPS)
- Ensure you're using a modern browser
- Disable browser popup blocker

### WOPI Token Errors
- Verify Redmine is accessible via HTTPS
- Check Setting.host_name is configured correctly
- Ensure Collabora server can reach Redmine server

## Reverting Changes

If you need to remove the plugin:

```bash
# Disable the plugin
cd /var/www/redmine
# Remove the plugin directory
rm -rf plugins/redmine_collabora_online

# Restart Redmine
sudo systemctl restart redmine

# Revert git changes (if using checkpoint)
git reset --hard HEAD~1
```

## Git Checkpoint

The plugin has been committed to git as checkpoint:
```bash
cd /var/www/redmine
git log --oneline | head -5
# Should show: "Add Redmine Collabora Online plugin for office document integration"
```

To revert to before the plugin was added:
```bash
cd /var/www/redmine
git reset --hard HEAD~1
```

## Contact & Support

For detailed documentation, see: `/var/www/redmine/plugins/redmine_collabora_online/README.md`

## Key Config Files

### Collabora Server URL
- **Location**: Administration → Plugins → Collabora Online
- **Setting**: `plugin_redmine_collabora_online.collabora_url`
- **Default**: `https://office.abellardss.co.za`
- **Required**: Yes

### Enable/Disable Plugin
- **Location**: Administration → Plugins → Collabora Online
- **Setting**: `plugin_redmine_collabora_online.enable_collabora`
- **Default**: `true`
- **Type**: Boolean

## What Happens When User Clicks "Edit in Collabora"

1. User clicks "Edit in Collabora" button
2. Plugin validates:
   - User is logged in
   - User has permission to edit the container
   - Collabora server URL is configured
3. Plugin generates WOPI URL with secure token
4. Collabora Online iframe loads with document
5. User can edit in real-time
6. Changes are saved back to Collabora/Redmine

## Next Features (Optional Enhancements)

The plugin provides a solid foundation for future enhancements:
- Document version history
- Collaborative editing notifications
- Comment integration
- File locking during editing
- Automatic backup to Redmine
- Format conversion

## Success Indicators

✅ Plugin appears in Admin → Plugins list
✅ Configure button is clickable
✅ Settings page shows URL field
✅ Collabora buttons appear on office attachments
✅ Documents open in Collabora iframe
✅ Editing works and saves correctly

You're all set! The plugin is ready to use.
