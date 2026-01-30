#!/bin/bash

az acr login --name springbootmicroervices
if [ $? -ne 0 ]; then
    echo "Failed to log in to Azure Container Registry. Please check your credentials."
    exit 1
fi

echo "Pushing Docker images to Azure Container Registry..."
docker push springbootmicroervices.azurecr.io/service-registry:latest
docker push springbootmicroervices.azurecr.io/api-gateway:latest
docker push springbootmicroervices.azurecr.io/order-service:latest
docker push springbootmicroervices.azurecr.io/payment-service:latest
docker push springbootmicroervices.azurecr.io/user-service:latest
docker push springbootmicroervices.azurecr.io/notification-service:latest

echo "Updating Azure Container Apps with new images..."

az containerapp update --name service-registry-app --resource-group springboot-rg --image springbootmicroervices.azurecr.io/service-registry:latest
az containerapp update --name api-gateway-app --resource-group springboot-rg --image springbootmicroervices.azurecr.io/api-gateway:latest
az containerapp update --name order-service-app --resource-group springboot-rg --image springbootmicroervices.azurecr.io/order-service:latest
az containerapp update --name payment-service-app --resource-group springboot-rg --image springbootmicroervices.azurecr.io/payment-service:latest
az containerapp update --name user-service-app --resource-group springboot-rg --image springbootmicroervices.azurecr.io/user-service:latest
az containerapp update --name notification-service-app --resource-group springboot-rg --image springbootmicroervices.azurecr.io/notification-service:latest