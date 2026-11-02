# This sets up different Matsuri environments

config_context :local_app_dev do
  default(:kube_context) { 'matsuri' }
  default(:region)       { 'local' }
  default(:namespace)    { 'app-dev' }
end

