# Load library files first
require_dependency File.expand_path('lib/redmine_collabora_online', __dir__)
require_dependency File.expand_path('lib/redmine_collabora_online/document_helper', __dir__)
require_dependency File.expand_path('lib/redmine_collabora_online/wopi_helper', __dir__)
require_dependency File.expand_path('lib/redmine_collabora_online/attachment_hook', __dir__)

Redmine::Plugin.register :redmine_collabora_online do
  name 'Redmine Collabora Online'
  author 'Roland Giesler'
  description 'Integration of Collabora Online with Redmine for viewing and editing office documents'
  version '1.0.3'
  url 'https://numbe.co.za'
  author_url 'mailto:roland@giesler.za.net'

  requires_redmine version_or_higher: '4.0.0'

  settings default: {
    'collabora_url' => 'https://office.abellardss.co.za',
    'enable_collabora' => 'true',
    'wopi_host' => ''
  }, partial: 'settings/collabora_online'

  menu :admin_menu, :collabora_online_settings,
       { controller: 'settings', action: 'plugin', id: :redmine_collabora_online },
       caption: 'Collabora Online'
end

# Configure view paths to include plugin views
# This ensures the plugin's partials override core Redmine ones
Rails.application.config.to_prepare do
  plugin_views_path = File.expand_path('app/views', File.dirname(__FILE__))
  
  # Prepend plugin views to all controllers
  ActionController::Base.prepend_view_path(plugin_views_path)
  
  # Log for debugging
  if defined?(Rails.logger) && Rails.logger
    Rails.logger.info "[Collabora Online] Plugin view path prepended: #{plugin_views_path}"
    Rails.logger.info "[Collabora Online] First 3 view paths: #{ActionController::Base.view_paths.first(3).map(&:to_s).join(', ')}"
  end
end
