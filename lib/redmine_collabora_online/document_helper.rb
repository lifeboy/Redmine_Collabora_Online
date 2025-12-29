module RedmineCollaboraOnline
  class DocumentHelper
    # Supported office document MIME types
    OFFICE_MIME_TYPES = {
      # Microsoft Office
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => :word,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => :calc,
      'application/vnd.openxmlformats-officedocument.presentationml.presentation' => :impress,
      'application/msword' => :word,
      'application/vnd.ms-excel' => :calc,
      'application/vnd.ms-powerpoint' => :impress,
      
      # OpenDocument
      'application/vnd.oasis.opendocument.text' => :word,
      'application/vnd.oasis.opendocument.spreadsheet' => :calc,
      'application/vnd.oasis.opendocument.presentation' => :impress,
      
      # Other formats
      'text/rtf' => :word,
      'application/rtf' => :word,
      'text/csv' => :calc,
      'text/plain' => :text,
    }.freeze

    # File extensions for office documents
    OFFICE_EXTENSIONS = %w[
      docx doc docm dotx dot dotm
      xlsx xls xlsm xltx xlt xltm
      pptx ppt pptm potx pot potm
      odt ott odg otg ods ots odp otp
      rtf csv txt
    ].freeze

    def self.is_office_document?(attachment)
      return false unless attachment

      # Check by MIME type
      return true if OFFICE_MIME_TYPES.key?(attachment.content_type)

      # Check by file extension
      ext = File.extname(attachment.filename).delete('.').downcase
      OFFICE_EXTENSIONS.include?(ext)
    end

    def self.get_document_type(attachment)
      return nil unless attachment

      # Check MIME type first
      mime_type = attachment.content_type
      return OFFICE_MIME_TYPES[mime_type] if OFFICE_MIME_TYPES.key?(mime_type)

      # Check by extension
      ext = File.extname(attachment.filename).delete('.').downcase
      case ext
      when 'docx', 'doc', 'docm', 'dotx', 'dot', 'dotm', 'rtf'
        :word
      when 'xlsx', 'xls', 'xlsm', 'xltx', 'xlt', 'xltm', 'csv'
        :calc
      when 'pptx', 'ppt', 'pptm', 'potx', 'pot', 'potm'
        :impress
      when 'odt', 'ott', 'ods', 'ots', 'odp', 'otp', 'odg', 'otg'
        :word # OpenDocument, general handling
      when 'txt'
        :text
      else
        nil
      end
    end

    def self.can_edit?(attachment, user)
      return false unless user

      # Check if user has permission to view the container
      if attachment.container.is_a?(Issue)
        attachment.container.visible? && user.allowed_to?(:edit_issues, attachment.container.project)
      elsif attachment.container.is_a?(Project)
        user.allowed_to?(:edit_files, attachment.container)
      else
        true # Default allow for other containers
      end
    end
  end
end
