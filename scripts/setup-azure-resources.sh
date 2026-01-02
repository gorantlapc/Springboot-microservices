#!/bin/bash
# Login to Azure and create infrastructure for the project
# Define variables
RESOURCE_GROUP="springboot-rg"
LOCATION="westeurope"
ACR_NAME="springbootmicroervices"
ENV_NAME="springboot-env"
SUBSCRIPTION_ID="430f2dae-20c6-47ce-abb7-fc675d7087b6"

echo "Logging in to Azure..."
az login
if [ $? -ne 0 ]; then
    echo "Azure login failed. Please check your credentials."
    exit 1
fi
az account set --subscription ${SUBSCRIPTION_ID}
echo "Creating resource group..."
az group create --name ${RESOURCE_GROUP} --location ${LOCATION}
echo "Creating Azure Container Registry..."
az acr create --resource-group ${RESOURCE_GROUP} --name ${ACR_NAME} --sku Basic
echo "Creating Azure Container Apps environment..."
az containerapp env create --name ${ENV_NAME} --resource-group ${RESOURCE_GROUP} --location ${LOCATION}
echo "Creating Azure Container Apps for each microservice..."
az containerapp create \
  --name api-gateway-app \
  --resource-group ${RESOURCE_GROUP} \
  --environment ${ENV_NAME} \
  --image springbootmicroervices.azurecr.io/api-gateway:latest \
  --min-replicas 1 \
  --max-replicas 2 \
  --cpu 0.5 --memory 1Gi --ingress 'external' --target-port 8084 \
  --env-vars \
    USER_SERVICE_URL=user-service-app:8082 \
    ORDER_SERVICE_URL=order-service-app:8085 \
    PAYMENT_SERVICE_URL=payment-service-app:8086 \
    NOTIFICATION_SERVICE_URL=notification-service-app:8087 \
    INVENTORY_SERVICE_URL=inventory-service-app:8088

az containerapp create --name order-service-app --resource-group ${RESOURCE_GROUP} --environment ${ENV_NAME} --image springbootmicroervices.azurecr.io/order-service:latest --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8085 --env-vars PAYMENT_SERVICE_URL=payment-service-app:8086 INVENTORY_SERVICE_URL=inventory-service-app:8088
az containerapp create --name payment-service-app --resource-group ${RESOURCE_GROUP} --environment ${ENV_NAME} --image springbootmicroervices.azurecr.io/payment-service:latest --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8086
az containerapp create --name user-service-app --resource-group ${RESOURCE_GROUP} --environment ${ENV_NAME} --image springbootmicroervices.azurecr.io/user-service:latest --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8082
az containerapp create --name notification-service-app --resource-group ${RESOURCE_GROUP} --environment ${ENV_NAME} --image springbootmicroervices.azurecr.io/notification-service:latest --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8087
az containerapp create --name inventory-service-app --resource-group ${RESOURCE_GROUP} --environment ${ENV_NAME} --image springbootmicroervices.azurecr.io/inventory-service:latest --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8088

echo "Create OIDC provider and assign roles..."
az ad app create --display-name "springboot-oidc-app"
APP_ID=$(az ad app list \
  --display-name springboot-oidc-app \
  --query "[0].appId" -o tsv)

az ad sp create --id "$APP_ID"
echo "Created service principal with App ID: $APP_ID"
az role assignment create --assignee "$APP_ID" --role "Contributor" --scope "/subscriptions/${SUBSCRIPTION_ID}"
az ad app federated-credential create --id "$APP_ID" --parameters '{ "name":"springboot-credential", "issuer":"https://token.actions.githubusercontent.com", "subject":"repo:gorantlapc/Springboot-microservices:environment:dev", "audiences":["api://AzureADTokenExchange"]}'

echo "Infrastructure creation completed."
