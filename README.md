# Evaluation der proxybasierten Ansätze von Istio und Cilium zur Zugriffskontrolle mit L7-Netzwerkrichtlinien in Cloudnativen Anwendungssystemen

Studiengang: M. Sc. Wirtschaftsinformatik (in Teilzeit) an der FH Münster \
Modul: Forschungs- und Entwicklungsprojekt\
Semester: Sommersemester 2022\
Student: Andre Farwick\

Repository zum Paper "Evaluation der proxybasierten Ansätze von Istio und Cilium zur Zugriffskontrolle mit L7-Netzwerkrichtlinien in Cloudnativen Anwendungssystemen". Das Projekt beinhaltet den notwendigen Code, um die Messungen zum Vergleich der Performance der L7-Netzwerkrichtlinien zwischen Cilium und Istio durchführen zu können.

Das Projekt ist so aufgebaut, dass alle Scripts, die zum Setup der Infrastruktur und zur Installation der Abhängigkeiten, sowie zur Durchführung der Messungen benötigt werden, in dem Ordner [scripts](./scripts/) liegen. 
Die Messergebnisse werden in dem Ordner [ergebnisse](./ergebnisse/) gespeichert. Falls noch keine Messungen durchgeführt worden sind, wird der Ordner initial erstellt. 
Die Richtlinien, die im Laufe der Messungen erstellt werden, werden im Ordner [richtlinien](./richtlinien/) zwischen gespeichert, bis sie nach dem Messdurchläufen wieder gelöscht werden. 
In dem [kubernetes](./kubernetes/) Ordner liegen die Kubernetes Ressourcen für das Deployment von Fortio, sowie eine kubeadm Konfiguration. 
In dem Ordner [evaluation](./evaluation/) befindet sich ein Jupyter-Notebook mit einem Python Script zur Auswertung der Messergebnisse. 

## Setup
### GKE-Cluster managen

Vorraussetzungen: 
- gcloud ist installiert
- kubectl ist installiert
- der Nutzer ist mit GCloud Account angemeldet: gcloud auth login
- Gcloud Project ist ausgewählt: gcloud config set project PROJECT_ID

Erstellen eines GKE Clusters: 
`./scripts/manage-gke-cluster.sh create-gke-cluster <num-nodes>`

### Kubeadm-Cluster managen

Ursprünglich war geplant für die Messungen ein Multi-Node Cluster mit Kubeadm mit virtuellen Maschinen der Datenverarbeitungszentrale der Fachhochschule Münster aufzusetzen. Aufgrund eines IT-Sicherheitsvorfalls konnte allerdings nicht auf die Systeme der Fachhochschule zugegriffen werden. 
Nichtsdestotrotz sind die Scripts weiterhin im Repo enthalten. Falls die Messungen an einem Kubeadm-Cluster nachvollzogen werden sollen, unterstützt beim Aufsetzen das Script `./scripts/manage-kubeadm-cluster.sh`.

Für jeden Clusterknoten müssen folgende Schritte durchgeführt werden: 
Kubernetes Abhängigkeiten installieren: \
`./scripts/manage-kubeadm-cluster.sh install-kubernetes-dependencies` \
Iptables konfigurieren: \
`./scripts/manage-kubeadm-cluster.sh install-kubernetes-dependencies` \
Swap ausschalten: \
`./scripts/manage-kubeadm-cluster.sh disable-swap` \
ContainerD als Runtime vorbereiten: \
`./scripts/manage-kubeadm-cluster.sh setup-containerd` \
Die zuvor genannten Schritte können auch mit dem Aufruf `./scripts/manage-kubeadm-cluster.sh setup-cluster-node` zusammen durchgeführt werden. \

Anschließend muss das Cluster initialisiert werden: \
`./scripts/manage-kubeadm-cluster.sh init-cluster` \
Nach der Initialisierung des Master-Knoten können weitere Knoten hinzugefügt werden, indem den Instruktionen aus der Konsolenausgabe gefolgt wird. 

## Messungen durchführen

Mit dem Script [testfaelle.sh](./scripts/testfaelle.sh) können alle Messungen zur Latenz, dem maximalen Durchsatz, sowie der Ressourcenbenutzung (CPU- und Arbeitsspeicher) durchgeführt werden.
In dem Testscript sind fogelnde Testfälle definiert: 
- latenz: minimale Last bei 1 Anfrage pro Sekunde und 4 threads
- durchsatz: maximale Last bei 32 threads
- richtlinien-skalierbarkeit: maximale Last bei 32 threads und sich ändernder Anzahl an Richtlinien
- pod-skalierbarkeit: maximale Last bei 32 threads und sich ändernder Anzahl an Server-Replikationen
Bei der Durchführung der Messungen wird jeweils die Latenz under Durchsatz mit Fortio gemessen und die Arbeitsspeicher und CPU-Benutzung mit top auf der Knoten, auf dem der Fortio Server läuft. \ 
Vor jedem Durchlaufen eines Testfall wird in dem Script Cilium als CNI-Plugin und gegebenenfalls Istio installiert, der Fortio Client und Server deployed, sowie die Richtlinien erstellt und angewendet. Nach der Durchführung des Tests werden die Richlinien, die Fortio deployments und Cilium und gegebenfalls Istio wieder gelöscht. 
Befehl zur Durchführung aller Testfälle (latenz, durchsatz, richltinien-skalierbarkeit, pod-skalierbarkeit): 
`testfaelle.sh alle-messungen <Implementierung> <Anzahl der Wiederholungen des Tests> <Hostname auf den der Fortio Client deployed werden soll> <Hostname auf den die Fortio Server deployed werden sollen>` \
Die Messungen können auch für die jeweiligen Testfälle einzeln wiederholt werden. 



