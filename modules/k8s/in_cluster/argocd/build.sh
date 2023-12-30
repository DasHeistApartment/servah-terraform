#!/bin/bash
kubectl kustomize . > kustomized.yaml
rm -r build
mkdir build
cp kustomized.yaml build/kustomized.yaml
cd build
yq -s '.kind + "-" + .metadata.name + ".yaml"' kustomized.yaml
rm kustomized.yaml
