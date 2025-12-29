# Redmine Collabora Online Plugin
# lib/redmine_collabora_online.rb

module RedmineCollaboraOnline
  class << self
    def is_office_document?(attachment)
      RedmineCollaboraOnline::DocumentHelper.is_office_document?(attachment)
    end

    def can_edit?(attachment, user)
      RedmineCollaboraOnline::DocumentHelper.can_edit?(attachment, user)
    end

    def is_enabled?
      Setting.plugin_redmine_collabora_online['enable_collabora'] == 'true' rescue false
    end

    def collabora_server_url
      Setting.plugin_redmine_collabora_online['collabora_url'] rescue nil
    end
  end
end
