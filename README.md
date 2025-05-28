# Open5GS_Kube_Amarisoft
This is a repository containing files for a 5G demo with Open5GS kubernetes core and Amarisoft Callbox gNB.

## Open5Gs 

For the Open5Gs core, I have used [Gradiant's Open5Gs Images](https://github.com/Gradiant/5g-images).

The ports/services being used are:

## Amarisoft Callbox Mini

For the Amarisoft Callbox, the standard gnb-sa.cfg is used, modifying only the NGAP address.



# Setup

You can deploy the setup using 'setup_open5gs.sh'. It will automatically install k3d and create the cluster.
