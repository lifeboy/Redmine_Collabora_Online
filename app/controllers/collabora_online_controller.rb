class CollaboraOnlineController < ApplicationController
  before_action :find_attachment, only: [:view, :edit, :wopi, :wopi_contents, :wopi_put_file, :wopi_put_contents]
  before_action :check_auth, only: [:view, :edit]
  before_action :set_cors_headers, only: [:wopi, :wopi_contents, :wopi_put_file, :wopi_put_contents, :test]
  skip_before_action :verify_authenticity_token, only: [:wopi, :wopi_contents, :wopi_put_file, :wopi_put_contents, :test]
  skip_before_action :check_if_login_required, only: [:wopi, :wopi_contents, :wopi_put_file, :wopi_put_contents, :test]

  # GET /collabora_online/view/:id
  def view
    @attachment = Attachment.find(params[:id])
    
    unless user_can_access_attachment?(@attachment, User.current)
      render_403
      return
    end

    unless RedmineCollaboraOnline.is_enabled?
      @error = I18n.t(:'label_collabora_not_configured')
      return
    end

    @collabora_url = RedmineCollaboraOnline::WopiHelper.collabora_url_for(@attachment, User.current, 'view')
    @can_edit = RedmineCollaboraOnline::DocumentHelper.can_edit?(@attachment, User.current)
    
    respond_to do |format|
      format.html { render :view }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # GET /collabora_online/edit/:id
  def edit
    @attachment = Attachment.find(params[:id])
    Rails.logger.info "[Collabora Online] EDIT: Found attachment #{@attachment.id}"
    
    unless user_can_edit_attachment?(@attachment, User.current)
      Rails.logger.info "[Collabora Online] EDIT: User cannot edit, rendering 403"
      render_403
      return
    end

    unless RedmineCollaboraOnline.is_enabled?
      Rails.logger.info "[Collabora Online] EDIT: Plugin not enabled"
      @error = I18n.t(:'label_collabora_not_configured')
      return
    end

    Rails.logger.info "[Collabora Online] EDIT: Generating Collabora URL..."
    @collabora_url = RedmineCollaboraOnline::WopiHelper.collabora_url_for(@attachment, User.current, 'edit')
    Rails.logger.info "[Collabora Online] Edit URL generated: #{@collabora_url}"
    
    respond_to do |format|
      format.html { render :edit }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Test endpoint to verify Collabora can reach Redmine
  def test
    set_cors_headers
    render json: { status: 'ok', message: 'Collabora server can reach Redmine', timestamp: Time.now.iso8601 }
  end

  # WOPI endpoint for Collabora Online
  def wopi
    Rails.logger.info "[Collabora] WOPI Request - attachment_id: #{params[:attachment_id]}, token: #{params[:access_token]&.[](0..30)}..."
    
    @attachment = Attachment.find(params[:attachment_id])
    
    # Validate access token if provided
    if params[:access_token].present?
      token_data = RedmineCollaboraOnline::WopiHelper.validate_access_token(params[:access_token])
      
      if token_data.nil?
        Rails.logger.warn "[Collabora] Invalid token: #{params[:access_token]&.[](0..30)}..."
        render json: { error: 'Invalid or expired token' }, status: :unauthorized
        return
      end
      
      # Set the user from the token
      user_id = token_data['user_id']
      user = User.find_by(id: user_id)
      
      if user.nil?
        Rails.logger.warn "[Collabora] User not found: #{user_id}"
        render json: { error: 'User not found' }, status: :unauthorized
        return
      end
      
      User.current = user
    elsif !User.current.logged?
      # No token and not logged in
      Rails.logger.warn "[Collabora] Not authenticated"
      render json: { error: 'Authentication required' }, status: :unauthorized
      return
    end
    
    # Check user has access
    unless user_can_access_attachment?(@attachment, User.current)
      Rails.logger.warn "[Collabora] Access denied for user #{User.current.id} to attachment #{@attachment.id}"
      render json: { error: 'Access denied' }, status: :forbidden
      return
    end

    Rails.logger.info "[Collabora] WOPI CheckFileInfo returning for #{@attachment.filename}"
    # Get file info for WOPI
    # Force JSON response format for WOPI compatibility
    request.format = :json
    render json: generate_wopi_response(@attachment, params[:access_token])
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "[Collabora] Attachment not found: #{params[:attachment_id]}"
    render json: { error: 'Attachment not found' }, status: :not_found
  rescue => e
    Rails.logger.error "[Collabora] WOPI Error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: e.message }, status: :internal_server_error
  end

  # WOPI GetFile endpoint - serves the actual document content
  def wopi_contents
    @attachment = Attachment.find(params[:attachment_id])
    
    # Validate access token if provided
    if params[:access_token].present?
      token_data = RedmineCollaboraOnline::WopiHelper.validate_access_token(params[:access_token])
      
      if token_data.nil?
        render text: 'Invalid or expired token', status: :unauthorized
        return
      end
      
      # Set the user from the token
      user_id = token_data['user_id']
      user = User.find_by(id: user_id)
      
      if user.nil?
        render text: 'User not found', status: :unauthorized
        return
      end
      
      User.current = user
    elsif !User.current.logged?
      # No token and not logged in
      render text: 'Authentication required', status: :unauthorized
      return
    end
    
    # Check user has access
    unless user_can_access_attachment?(@attachment, User.current)
      render text: 'Access denied', status: :forbidden
      return
    end

    # Serve the file
    send_file(
      @attachment.diskfile,
      filename: @attachment.filename,
      type: @attachment.content_type,
      disposition: 'inline'
    )
  rescue ActiveRecord::RecordNotFound
    render text: 'Attachment not found', status: :not_found
  end

  # WOPI PutFile endpoint - handles document saves from Collabora
  def wopi_put_file
    @attachment = Attachment.find(params[:attachment_id])
    
    Rails.logger.info "[Collabora] WOPI PutFile Request - attachment_id: #{params[:attachment_id]}, size: #{request.content_length}"
    
    # Validate access token if provided
    if params[:access_token].present?
      token_data = RedmineCollaboraOnline::WopiHelper.validate_access_token(params[:access_token])
      
      if token_data.nil?
        Rails.logger.warn "[Collabora] PutFile: Invalid token"
        request.format = :json
        render json: { error: 'Invalid or expired token' }, status: :unauthorized
        return
      end
      
      # Set the user from the token
      user_id = token_data['user_id']
      user = User.find_by(id: user_id)
      
      if user.nil?
        Rails.logger.warn "[Collabora] PutFile: User not found: #{user_id}"
        request.format = :json
        render json: { error: 'User not found' }, status: :unauthorized
        return
      end
      
      User.current = user
    elsif !User.current.logged?
      Rails.logger.warn "[Collabora] PutFile: Not authenticated"
      request.format = :json
      render json: { error: 'Authentication required' }, status: :unauthorized
      return
    end
    
    # Check user can edit
    unless user_can_edit_attachment?(@attachment, User.current)
      Rails.logger.warn "[Collabora] PutFile: Access denied for user #{User.current.id} to attachment #{@attachment.id}"
      request.format = :json
      render json: { error: 'Access denied' }, status: :forbidden
      return
    end

    begin
      # Read the file content from the request body
      file_content = request.body.read
      
      Rails.logger.info "[Collabora] PutFile: Received #{file_content.bytesize} bytes for attachment #{@attachment.id}"
      
      # Save the new version to disk
      file_path = @attachment.diskfile
      FileUtils.mkdir_p(File.dirname(file_path))
      File.binwrite(file_path, file_content)
      
      # Update attachment metadata
      @attachment.filesize = file_content.bytesize
      @attachment.save!
      
      Rails.logger.info "[Collabora] PutFile: Successfully saved attachment #{@attachment.id}"
      
      # Return WOPI PutFile response - ItemVersion should be the new file's mtime
      file_mtime = File.mtime(file_path).to_i
      request.format = :json
      render json: {
        ItemVersion: file_mtime
      }, status: :ok
    rescue => e
      Rails.logger.error "[Collabora] PutFile Error: #{e.message}\n#{e.backtrace.join("\n")}"
      request.format = :json
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # WOPI PutFile for contents endpoint (alternative save path)
  def wopi_put_contents
    @attachment = Attachment.find(params[:attachment_id])
    
    Rails.logger.info "[Collabora] WOPI PutFile (contents) Request - attachment_id: #{params[:attachment_id]}, size: #{request.content_length}"
    
    # Validate access token if provided
    if params[:access_token].present?
      token_data = RedmineCollaboraOnline::WopiHelper.validate_access_token(params[:access_token])
      
      if token_data.nil?
        Rails.logger.warn "[Collabora] PutFile: Invalid token"
        request.format = :json
        render json: { error: 'Invalid or expired token' }, status: :unauthorized
        return
      end
      
      # Set the user from the token
      user_id = token_data['user_id']
      user = User.find_by(id: user_id)
      
      if user.nil?
        Rails.logger.warn "[Collabora] PutFile: User not found: #{user_id}"
        request.format = :json
        render json: { error: 'User not found' }, status: :unauthorized
        return
      end
      
      User.current = user
    elsif !User.current.logged?
      Rails.logger.warn "[Collabora] PutFile: Not authenticated"
      request.format = :json
      render json: { error: 'Authentication required' }, status: :unauthorized
      return
    end
    
    # Check user can edit
    unless user_can_edit_attachment?(@attachment, User.current)
      Rails.logger.warn "[Collabora] PutFile: Access denied for user #{User.current.id} to attachment #{@attachment.id}"
      request.format = :json
      render json: { error: 'Access denied' }, status: :forbidden
      return
    end

    begin
      # Read the file content from the request body
      file_content = request.body.read
      
      Rails.logger.info "[Collabora] PutFile: Received #{file_content.bytesize} bytes for attachment #{@attachment.id}"
      
      # Save the new version to disk - use binary write mode for binary files
      file_path = @attachment.diskfile
      FileUtils.mkdir_p(File.dirname(file_path))
      File.binwrite(file_path, file_content)
      
      # Update attachment metadata
      @attachment.filesize = file_content.bytesize
      @attachment.save!
      
      Rails.logger.info "[Collabora] PutFile: Successfully saved attachment #{@attachment.id}"
      
      # Return WOPI PutFile response - ItemVersion should be the new file's mtime
      file_mtime = File.mtime(file_path).to_i
      request.format = :json
      render json: {
        ItemVersion: file_mtime
      }, status: :ok
    rescue => e
      Rails.logger.error "[Collabora] PutFile Error: #{e.message}\n#{e.backtrace.join("\n")}"
      request.format = :json
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def find_attachment
    @attachment = Attachment.find(params[:id] || params[:attachment_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_auth
    require_login unless User.current.logged?
  end

  def user_can_access_attachment?(attachment, user)
    return false unless user.logged?

    if attachment.container.is_a?(Issue)
      attachment.container.visible?
    elsif attachment.container.is_a?(Project)
      attachment.container.active?
    elsif attachment.container.is_a?(News)
      true
    else
      true
    end
  end

  def user_can_edit_attachment?(attachment, user)
    return false unless user.logged?

    if attachment.container.is_a?(Issue)
      attachment.container.visible? && user.allowed_to?(:edit_issues, attachment.container.project)
    elsif attachment.container.is_a?(Project)
      user.allowed_to?(:edit_files, attachment.container)
    else
      false
    end
  end

  def generate_wopi_response(attachment, access_token = nil)
    download_url = if access_token.present?
      "#{Setting.host_name}/collabora_online/wopi/#{attachment.id}/contents?access_token=#{access_token}"
    else
      download_named_attachment_url(attachment, attachment.filename)
    end
    
    # Use file's actual modification time as version (changes when file is saved)
    file_path = attachment.diskfile
    file_mtime = if File.exist?(file_path)
                    File.mtime(file_path).to_i
                  else
                    attachment.created_on.to_i
                  end
    
    {
      BaseFileName: attachment.filename,
      Size: attachment.filesize,
      Version: file_mtime,
      OwnerId: attachment.author.id.to_s,
      UserId: User.current.id.to_s,
      UserFriendlyName: "#{User.current.firstname} #{User.current.lastname}",
      UserCanWrite: user_can_edit_attachment?(attachment, User.current),
      UserCanRename: false,
      UserCanNotWriteRelated: true,
      UserCanCreateWritableRelated: false,
      UserCanRead: true,
      BreadcrumbBrandName: 'Redmine',
      BreadcrumbFolderName: attachment.container.is_a?(Issue) ? "Issue ##{attachment.container.id}" : 'Project',
      SupportsLocks: false,
      SupportsUpdate: true,
      SupportsCobalt: false,
      SupportsRename: false,
      SupportsDeleteFile: false,
      SupportsExtendedLockLength: false,
      DisablePrint: false,
      DisableExport: false,
      DisableCopy: false,
      CloseButtonClosesWindow: true,
      DownloadUrl: download_url,
      FileSharingUrl: nil,
      HostEditUrl: nil,
      HostViewUrl: nil,
      HostName: Setting.host_name,
      ServerError: nil,
      IsAnonymousUser: User.current.anonymous?,
      LastModifiedTime: File.mtime(file_path).iso8601,
      IsLoopbackRequest: false
    }
  end

  private

  # Handle CORS preflight requests
  def handle_options_request
    set_cors_headers
    render json: {}, status: :ok
  end

  def set_cors_headers
    # Allow Collabora Online server to make cross-origin requests
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, OPTIONS, DELETE'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    response.headers['Access-Control-Max-Age'] = '3600'
  end
end
