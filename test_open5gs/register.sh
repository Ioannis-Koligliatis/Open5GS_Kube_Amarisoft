#!/bin/bash

# Adjust these to your Kubernetes setup:
NAMESPACE="default"  # your namespace with MongoDB and Open5GS
MONGO_SERVICE="mongo"  # your mongo service name
MONGO_PORT=27017
DB_URI="mongodb://${MONGO_SERVICE}.${NAMESPACE}.svc.cluster.local:${MONGO_PORT}/open5gs"

# Your UE IMSIs (example IMSIs for 10 UEs)
IMSIS=(
  "001010000000001"
  "001010000000002"
  "001010000000003"
  "001010000000004"
  "001010000000005"
  "001010000000006"
  "001010000000007"
  "001010000000008"
  "001010000000009"
  "001010000000010"
  "001010000000011"
  "001010000000012"
)

KI="465B5CE8B199B49FAA5F0A2EE238A6BC"
OPC="E8ED289DEBA952E4283B54E88E6183CA"

# Container image to run (adjust if you have your own)
DBCTL_IMAGE="gradiant/open5gs-dbctl:0.10.3"

# Loop over IMSIs and register each UE
for IMSI in "${IMSIS[@]}"; do
  echo "Registering UE with IMSI: $IMSI"

  kubectl run --rm -i --restart=Never open5gs-dbctl-$IMSI \
    --namespace $NAMESPACE \
    --image $DBCTL_IMAGE \
    --env DB_URI=$DB_URI \
    --command -- /bin/bash -c "open5gs-dbctl add $IMSI $KI $OPC"
  
  if [ $? -ne 0 ]; then
    echo "Failed to add IMSI $IMSI"
  else
    echo "Successfully added IMSI $IMSI"
  fi
done

