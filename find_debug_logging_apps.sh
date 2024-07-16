#!/bin/bash

# Define namespace if needed, otherwise set to all namespaces
NAMESPACE=${1:-"--all-namespaces"}

echo "Capturing applications with logging level set to DEBUG in namespace: $NAMESPACE"

# Get all pods in the specified namespace
pods=$(kubectl get pods $NAMESPACE -o json)

# Parse through the pods to find containers with logging level set to DEBUG
echo "$pods" | jq -r '
  .items[] | 
  .metadata as $metadata | 
  .spec.containers[] | 
  select(
    (.env[]? | select(.name == "LOG_LEVEL" and .value == "DEBUG")) or
    (.envFrom[]?.configMapRef.name as $configMapRef | 
     $metadata.namespace as $namespace | 
     $configMapRef | 
     if . != null then 
       (input | select(.metadata.name == $configMapRef and .metadata.namespace == $namespace) | 
        .data.LOG_LEVEL == "DEBUG") 
     else 
       false 
     end
    )
  ) | 
  "Namespace: " + $metadata.namespace + ", Pod: " + $metadata.name + ", Container: " + .name
' --slurpfile pods <(kubectl get configmaps $NAMESPACE -o json)
