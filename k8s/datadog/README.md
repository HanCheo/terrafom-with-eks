helm repo add datadog https://helm.datadoghq.com
helm repo update

helm install datadog 
datadog/datadog \
--namespace datadog \
--create-namespace \
--values datadog/values.yaml