#!/bin/bash
# Login to Azure and create infrastructure for the project
# Define variables
RESOURCE_GROUP="springboot-rg"
LOCATION="westeurope"
ACR_NAME="springbootmicroervices"
ENV_NAME="springboot-env"
SUBSCRIPTION_ID="430f2dae-20c6-47ce-abb7-fc675d7087b6"
SB_NAMESPACE="pctech" # Must be globally unique
TOPIC_NAME="alerts"

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

echo "Creating Azure Service Bus Namespace and Topic..."
# Create Service Bus Namespace (Standard tier is required for Topics/PubSub)
az servicebus namespace create --resource-group $RESOURCE_GROUP --name $SB_NAMESPACE --location $LOCATION --sku Standard
# Create the Topic
az servicebus topic create --resource-group $RESOURCE_GROUP --namespace-name $SB_NAMESPACE --name $TOPIC_NAME

echo "Assigning ACR pull role to Container Apps environment..."

ACR_ID=$(az acr show -n $ACR_NAME -g $RG --query id -o tsv)

az containerapp env identity assign \
  --name ${ENV_NAME} \
  --resource-group ${RESOURCE_GROUP}

ENV_PRINCIPAL_ID=$(az containerapp env show \
  --name ${ENV_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query identity.principalId -o tsv)

az role assignment create \
  --assignee $ENV_PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_ID

echo "Creating Azure Container Apps for each microservice..."
az containerapp create \
  --name api-gateway-app \
  --resource-group ${RESOURCE_GROUP} \
  --environment ${ENV_NAME} \
  --image springbootmicroervices.azurecr.io/api-gateway:latest \
  --registry-server ${ACR_NAME}.azurecr.io \
  --min-replicas 1 \
  --max-replicas 2 \
  --cpu 0.5 --memory 1Gi --ingress 'external' --target-port 8084 \
  --env-vars \
    USER_SERVICE_URL=http://user-service-app \
    ORDER_SERVICE_URL=http://order-service-app \
    PAYMENT_SERVICE_URL=http://payment-service-app \
    NOTIFICATION_SERVICE_URL=http://notification-service-app \
    INVENTORY_SERVICE_URL=http://inventory-service-app \
    JAVA_TOOL_OPTIONS="-Dnetty.dns.resolver.type=native"

az containerapp create \
  --name order-service-app \
  --resource-group ${RESOURCE_GROUP} \
  --environment ${ENV_NAME} \
  --image springbootmicroervices.azurecr.io/order-service:latest \
  --registry-server ${ACR_NAME}.azurecr.io \
  --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8085 \
  --enable-dapr true --dapr-app-id "order-service" --dapr-app-port 8085 --dapr-app-protocol "http" \
  --env-vars \
    LOG_LEVEL_ORDERSERVICE="DEBUG" \

az containerapp create \
  --name payment-service-app \
  --resource-group ${RESOURCE_GROUP} \
  --environment ${ENV_NAME} \
  --image springbootmicroervices.azurecr.io/payment-service:latest \
  --registry-server ${ACR_NAME}.azurecr.io \
  --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8086 \
  --enable-dapr true --dapr-app-id "payment-service" --dapr-app-port 8086 --dapr-app-protocol "http"

az containerapp create \
  --name user-service-app \
  --resource-group ${RESOURCE_GROUP} \
  --environment ${ENV_NAME} \
  --image springbootmicroervices.azurecr.io/user-service:latest \
  --registry-server ${ACR_NAME}.azurecr.io \
  --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8082

az containerapp create \
  --name notification-service-app \
  --resource-group ${RESOURCE_GROUP} \
  --environment ${ENV_NAME} \
  --image springbootmicroervices.azurecr.io/notification-service:latest \
  --registry-server ${ACR_NAME}.azurecr.io \
  --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8087 \
  --enable-dapr true --dapr-app-id "notification-service" --dapr-app-port 8087 --dapr-app-protocol "http"

az containerapp create \
  --name inventory-service-app \
  --resource-group ${RESOURCE_GROUP} \
  --environment ${ENV_NAME} \
  --image springbootmicroervices.azurecr.io/inventory-service:latest \
  --registry-server ${ACR_NAME}.azurecr.io \
  --min-replicas 1 --max-replicas 2 --cpu 0.5 --memory 1Gi --ingress 'internal' --target-port 8088 \
  --enable-dapr true --dapr-app-id "inventory-service" --dapr-app-port 8088 --dapr-app-protocol "http"


echo "Assigning Service Bus roles to Order Service Container App..."
# 1. Get the Principal ID of your Container App (replace <app-name>)
PRINCIPAL_ID=$(az containerapp identity assign --name order-service-app --resource-group $RESOURCE_GROUP --system-assigned --query principalId -o tsv)

# 2. Get the Resource ID of your Resource group's Service Bus Namespace
RG_ID=$(az group show --name $RESOURCE_GROUP --query id -o tsv)

# 3. Grant "Azure Service Bus Data Receiver" and "Sender" roles to the App
az role assignment create --assignee $PRINCIPAL_ID --role "Azure Service Bus Data Owner" --scope $RG_ID

echo "Assigning Service Bus roles to Notification Service Container App..."
# 1. Get the Principal ID of your Container App (replace <app-name>)
PRINCIPAL_ID_NOTIF=$(az containerapp identity assign --name notification-service-app --resource-group $RESOURCE_GROUP --system-assigned --query principalId -o tsv)
# 2. Grant "Azure Service Bus Data Receiver" role to the App
az role assignment create --assignee $PRINCIPAL_ID_NOTIF --role "Azure Service Bus Data Owner" --scope $RG_ID

az containerapp env dapr-component set \
    --name $ENV_NAME \
    --resource-group $RESOURCE_GROUP \
    --dapr-component-name pubsub \
    --yaml ./dapr/azure/pubsub.yaml


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
