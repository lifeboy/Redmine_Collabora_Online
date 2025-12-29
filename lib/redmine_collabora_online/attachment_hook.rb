module RedmineCollaboraOnline
  class AttachmentHook < Redmine::Hook::ViewListener
    # Hook into attachment display to add Collabora Online buttons
    def view_attachments_show_attachment(context = {})
      attachment = context[:attachment]
      user = context[:user] || User.current
      view = context[:view]
      
      return '' unless attachment
      return '' unless RedmineCollaboraOnline::DocumentHelper.is_office_document?(attachment)
      return '' unless RedmineCollaboraOnline.is_enabled?
      return '' unless view

      output = ''.html_safe

      # Add view button
      view_link = view.link_to(
        "#{view.sprite_icon('eye')} #{I18n.t(:'label_collabora_view')}".html_safe,
        { controller: 'collabora_online', action: 'view', id: attachment.id },
        class: 'icon icon-eye collabora-view-btn',
        target: '_blank',
        rel: 'noopener noreferrer',
        title: I18n.t(:'label_collabora_view')
      )
      output = output + view_link + ' '.html_safe

      # Add edit button if user has permission
      if RedmineCollaboraOnline::DocumentHelper.can_edit?(attachment, user)
        edit_link = view.link_to(
          "#{view.sprite_icon('edit')} #{I18n.t(:'label_collabora_edit')}".html_safe,
          { controller: 'collabora_online', action: 'edit', id: attachment.id },
          class: 'icon icon-edit collabora-edit-btn',
          target: '_blank',
          rel: 'noopener noreferrer',
          title: I18n.t(:'label_collabora_edit')
        )
        output = output + edit_link
      end

      output
    end
  end
end
