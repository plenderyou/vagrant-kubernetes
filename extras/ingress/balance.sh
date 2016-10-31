#! /bin/bash


while true
do
    IP=$(kubectl get pod -o wide | awk '/nginx-ingr/ { print $6 }')
    balance -f -b $(hostname -i) 80 $IP
    sleep 20
done
