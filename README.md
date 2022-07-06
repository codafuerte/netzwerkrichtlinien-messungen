# Netzwerkrichtlinien Messungen

Das Projekt beinhaltet den notwendigen Code, um die Messungen zum Vergleich der Performance der L7-Netzwerkrichtlinien zwischen Cilium und Istio durchführen zu können. 

## GKE-Cluster managen

Vorraussetzungen: 
- gcloud ist installiert
- kubectl ist installiert
- der Nutzer ist mit GCloud Account angemeldet: gcloud auth login
- Gcloud Project ist ausgewählt: gcloud config set project PROJECT_ID

Erstellen eines GKE Clusters: 
`./scripts/manage-gke-cluster.sh create-gke-cluster <num-nodes>`


