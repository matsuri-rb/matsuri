# This sets up different Matsuri environments
#
# Environment names map to kubectl contexts via kube_context
# (map_env_to_kube_context is set in config/matsuri.rb). The local
# environments all point at the minikube "matsuri" profile, one
# namespace per stack.

config_context :local_app_dev do
  default(:kube_context) { 'matsuri' }
  default(:region)       { 'local' }
  default(:namespace)    { 'app-dev' }
end

config_context :local_billing_dev do
  default(:kube_context) { 'matsuri' }
  default(:region)       { 'local' }
  default(:namespace)    { 'billing-dev' }
end

config_context :local_checkout_dev do
  default(:kube_context) { 'matsuri' }
  default(:region)       { 'local' }
  default(:namespace)    { 'checkout-dev' }
end

# Staging contexts are illustrative: a real repo names the context the
# provider hands out (for GKE, let gcloud own authentication and
# naming).
config_context :billing_staging do
  default(:kube_context) { 'gke_acme-platform_us-central1_staging' }
  default(:region)       { 'us-central1' }
  default(:namespace)    { 'billing' }
end

config_context :checkout_staging do
  default(:kube_context) { 'gke_acme-platform_us-central1_staging' }
  default(:region)       { 'us-central1' }
  default(:namespace)    { 'checkout' }
end
