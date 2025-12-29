module RedmineCollaboraOnline
  class WopiHelper
    WOPI_SECRET = 'redmine-collabora-online-secret-key-change-in-production'

    # Generates a WOPI access token
    def self.generate_access_token(attachment_id, user_id, expires_in = 24.hours)
      payload = {
        attachment_id: attachment_id,
        user_id: user_id,
        exp: (Time.current + expires_in).to_i,
        iat: Time.current.to_i
      }

      # Create a simple HMAC-SHA256 token
      token_string = "#{attachment_id}:#{user_id}:#{payload[:exp]}"
      signature = OpenSSL::HMAC.hexdigest('SHA256', WOPI_SECRET, token_string)
      
      # Return token in format: data.signature
      "#{Base64.urlsafe_encode64(token_string).chomp}.#{signature}"
    end

    # Validates a WOPI access token
    def self.validate_access_token(token)
      begin
        parts = token.split('.')
        return nil unless parts.length == 2
        
        # Add padding if needed for base64 decoding
        encoded_part = parts[0]
        padding = encoded_part.length % 4
        encoded_part += '=' * (4 - padding) if padding > 0
        
        token_string = Base64.urlsafe_decode64(encoded_part)
        provided_signature = parts[1]
        
        Rails.logger.info "[Collabora] Token validation - decoded: #{token_string}, sig: #{provided_signature[0..20]}..."
        
        # Verify signature
        expected_signature = OpenSSL::HMAC.hexdigest('SHA256', WOPI_SECRET, token_string)
        
        Rails.logger.info "[Collabora] Expected sig: #{expected_signature[0..20]}..., Match: #{provided_signature == expected_signature}"
        
        return nil unless provided_signature == expected_signature
        
        # Parse the token
        attachment_id, user_id, exp = token_string.split(':')
        
        Rails.logger.info "[Collabora] Parsed - attachment: #{attachment_id}, user: #{user_id}, exp: #{exp}, now: #{Time.current.to_i}"
        
        # Check expiration
        return nil if exp.to_i < Time.current.to_i
        
        {
          'attachment_id' => attachment_id.to_i,
          'user_id' => user_id.to_i,
          'exp' => exp.to_i
        }
      rescue => e
        Rails.logger.info "[Collabora] Token validation error: #{e.message}"
        nil
      end
    end

    # Generates the Collabora Online URL for embedding
    def self.collabora_url_for(attachment, user, action = 'view')
      collabora_server = Setting.plugin_redmine_collabora_online['collabora_url']
      return nil unless collabora_server

      access_token = generate_access_token(attachment.id, user.id)
      
      # WOPI token TTL in milliseconds (24 hours from now)
      access_token_ttl = (Time.now + 24.hours).to_i * 1000
      
      # The WOPISrc URL must include the access token and TTL as query parameters
      # no_auth_header tells Collabora to trust the access_token parameter instead of expecting HTTP auth
      wopi_src = "#{Setting.host_name}/collabora_online/wopi/#{attachment.id}?access_token=#{access_token}&access_token_ttl=#{access_token_ttl}&no_auth_header="

      # Use /browser/ endpoint which loads the Collabora UI (like Nextcloud does)
      # The browser endpoint serves the HTML UI page that initiates the WebSocket connection
      # Parameters needed:
      # - WOPISrc: the WOPI server URL (for initial file info)
      # - title: document filename/title
      # - compat: /ws indicates WebSocket compatibility
      encoded_wopi_src = CGI.escape(wopi_src)
      collabora_url = "#{collabora_server}/browser/#{SecureRandom.hex(8)}/cool.html?WOPISrc=#{encoded_wopi_src}&title=#{CGI.escape(attachment.filename)}&compat=/ws"
      
      collabora_url
    end

    # Get document type for Collabora
    def self.get_document_type(attachment)
      ext = File.extname(attachment.filename).delete('.').downcase
      
      case ext
      when 'docx', 'doc', 'docm', 'dotx', 'dot', 'dotm', 'odt', 'rtf', 'txt'
        'text'
      when 'xlsx', 'xls', 'xlsm', 'xltx', 'xlt', 'xltm', 'ods', 'csv'
        'spreadsheet'
      when 'pptx', 'ppt', 'pptm', 'potx', 'pot', 'potm', 'odp'
        'presentation'
      else
        'document'
      end
    end

    private

    def self.get_user_language(user)
      user.language || 'en'
    end
  end
end
