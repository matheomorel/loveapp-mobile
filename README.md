# LoveApp iOS

Application iOS native qui affiche le site LoveApp dans une `WKWebView`.

## Configurer l’adresse du site

Modifiez `LoveApp/site-url.txt` avant de lancer ou distribuer l’application. Entrez une URL complète, une par ligne, par exemple `https://mon-site.fr`. Pour tester un serveur de développement sur le même Wi-Fi, utilisez l’adresse IP du PC et le port Vite (par exemple `http://192.168.1.25:5173`), pas `localhost`.

Le trafic HTTP est autorisé pour les essais sur le réseau local; utilisez HTTPS en production. iOS et Safari n’autorisent les appels caméra/micro que depuis une origine HTTPS. Les certificats HTTPS non fiables restent refusés; pour un serveur local, installez et approuvez son certificat sur l’iPhone.

La sélection de fichiers est gérée par iOS. L’accès à la caméra et au microphone est demandé par iOS lorsque le site démarre un appel.

## Construire et lancer

1. Sur un Mac, installez Xcode 15 ou une version plus récente.
2. Ouvrez `LoveApp.xcodeproj`.
3. Sélectionnez une équipe de signature dans les réglages de la cible si vous lancez sur un appareil physique.
4. Sélectionnez un simulateur ou un appareil iOS et lancez la cible **LoveApp**.
