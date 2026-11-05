# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

`revia-app` est l'app iOS de **RevIA** (SwiftUI, SwiftData, MVVM, iOS 17+). L'utilisateur importe un PDF de cours et l'app le transforme en QCM de révision, puis planifie les révisions par répétition espacée (Leitner).

- **La spécification fonctionnelle est le `README.md`** : phases 1 à 3, modèle de données, règles de Leitner, choix techniques. À lire avant tout chantier. Ce fichier-ci ne le répète pas : il ajoute le contrat de l'API, la mise en place technique et les écarts à connaître.
- **L'app ne parle qu'à `revia-api`** (dépôt voisin `../revia-api`, privé), qui détient la clé de l'IA. Aucune clé d'IA ni aucun appel direct à un fournisseur d'IA dans l'app.
- **Ce dépôt est public.** Jamais de secret, de jeton, d'adresse IP, de nom de machine ni de donnée personnelle dans le code, les commits ou ce fichier. `Config/Secrets.xcconfig` est ignoré par Git.
- **On ne modifie que l'app ici.** Un besoin côté API (nouveau champ, nouveau code d'erreur) se signale à l'utilisateur. On ne touche jamais `../revia-api` depuis ce dépôt.

## État actuel et écarts à connaître

- **Le projet Xcode existe, mais l'app n'est pas implémentée.** En dehors de `RevIAApp.swift` et d'un `RootView` minimal, les fichiers `.swift` ne contiennent que leur en-tête : l'arborescence est un plan.
- **Outils** : Xcode 27, Swift 6.4, simulateurs iOS 27. Le README demande donc Xcode 27+.
- **Mode de langage Swift 6, avec isolation par défaut sur `MainActor`** (`SWIFT_DEFAULT_ACTOR_ISOLATION`, réglage par défaut d'Xcode 27, sur la cible `RevIA` seulement) :
  - le code de l'app est `@MainActor` sans annotation, ViewModels `@Observable` compris ;
  - ce qui doit être `Sendable` ou tourner hors du thread principal (types d'échange avec l'API, client réseau si besoin) se déclare `nonisolated` ;
  - la cible `RevIATests` n'a pas ce réglage : un test qui manipule des types de l'app est `@MainActor` ;
  - `URLSession` en `async`/`await` ;
  - avec `SWIFT_APPROACHABLE_CONCURRENCY`, une fonction `async` `nonisolated` s'exécute sur l'acteur de l'appelant : il faut `@concurrent` pour la sortir du thread principal. Inutile pour le client de l'API, qui attend le réseau sans bloquer.
- `ExtractionTexte.swift` n'est pas nécessaire à la génération, puisque l'API envoie le PDF brut à l'IA, qui lit aussi les pages scannées. Ne l'implémenter que pour un besoin d'affichage ou de recherche.

## Projet Xcode

- **Format Xcode 27** : `RevIA.xcodeproj/project.xcproj` est un fichier texte (JSON avec virgules finales), et non plus un `.pbxproj`. Claude peut y modifier les réglages et les cibles, puis **vérifie toujours avec `xcodebuild build` et `xcodebuild test`**. Ce format ne s'ouvre pas dans un Xcode antérieur à la version 27.
- **Dossiers synchronisés** (`"kind": "folder"`) : tout fichier créé sur disque dans `RevIA/` ou `RevIATests/` rejoint automatiquement sa cible, sans toucher au projet.
- **Pas de schéma partagé** : Xcode et `xcodebuild` créent automatiquement le schéma `RevIA`. Le partager (`xcshareddata/xcschemes`) le jour où une CI en aura besoin.
- **Identifiant d'équipe (`DEVELOPMENT_TEAM`) jamais versionné**, puisque le dépôt est public. Le simulateur n'en a pas besoin. Pour un iPhone réel, il passera par `Secrets.xcconfig` ; d'ici là, le choisir dans Xcode sans commiter la modification du projet.
- Identifiant de bundle : choisi par l'utilisateur, jamais écrit ici.
- **`Info.plist` de Debug** : `Config/Info-Debug.plist`, hors des dossiers synchronisés, branché par `"INFOPLIST_FILE[config=Debug]"` et fusionné par Xcode avec l'`Info.plist` généré (`GENERATE_INFOPLIST_FILE`). Rien en Release.
- **Reste à brancher, par l'utilisateur dans Xcode (facultatif)** : `Config/Secrets.xcconfig` comme configuration de base (Projet → Info → Configurations). D'ici là, `$(API_BASE_URL)` et `$(API_TOKEN)` arrivent vides, et l'adresse et le jeton se saisissent dans Réglages.

## Commandes

```bash
cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig   # puis API_BASE_URL et API_TOKEN

xcodebuild -project RevIA.xcodeproj -scheme RevIA \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
xcodebuild test -project RevIA.xcodeproj -scheme RevIA \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
xcodebuild test -project RevIA.xcodeproj -scheme RevIA \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:RevIATests/DecodageQCMTests                   # un seul fichier de tests

xcrun simctl list devices available                          # simulateurs installés
# Si deux simulateurs portent le même nom, xcodebuild prend le premier et affiche un avertissement :
# supprimer le doublon (xcrun simctl delete <id>) ou viser 'platform=iOS Simulator,id=<id>'.

# API locale, pour les essais manuels (dans ../revia-api, avec son .env)
make dev                                                     # écoute sur 0.0.0.0:8000
```

## Contrat avec revia-api

**Référence unique** : `../revia-api/tests/fixtures/reponse_exemple.json`. `RevIATests/Fixtures/reponse_exemple.json` en est une **copie exacte**, testée par `DecodageQCMTests` : si le format change d'un côté, un test échoue de l'autre. Copier le fichier plutôt que le réécrire. Documentation interactive : `<API>/docs`. Spécification : `<API>/openapi.json`.

### Requête : `POST /v1/qcm`

- En-tête `X-API-Token: <jeton>`.
- Corps `multipart/form-data` :
  - `file` : le PDF. L'API vérifie la signature `%PDF-` et une taille maximale de **20 Mo**. Vérifier la taille côté app avant l'envoi, pour éviter un 413 après un long upload.
  - `nb_questions` : entier de 1 à 30, 10 par défaut.
- **Attention : le champ du formulaire est en snake_case (`nb_questions`), alors que le JSON de réponse est en camelCase.**
- `URLSession` ne construit pas de multipart : écrire le corps à la main (frontière, `Content-Disposition: form-data; name="file"; filename="cours.pdf"`, `Content-Type: application/pdf`).

### Réponse 200

```json
{"qcm": [{"question": "…", "propositions": ["…", "…", "…", "…"], "indexBonneReponse": 1,
          "explication": "…", "theme": "…"}],
 "avertissement": null}
```

- `qcm` contient au moins une question. `propositions` en compte 2 à 6, en pratique 4. **L'ordre est déjà mélangé par l'API : ne pas le remélanger.** `indexBonneReponse` désigne toujours une proposition existante.
- `theme` est un libellé court et stable, partagé par les questions d'une même notion : c'est la clé des statistiques par thème.
- `avertissement` vaut `null`, ou contient une phrase quand le document ne permet pas de produire le nombre de questions demandé. L'afficher quand il est présent.
- Correspondance avec le README : la réponse se décode dans `struct QCM: Codable`, qui représente une question, à l'intérieur d'une enveloppe `{qcm, avertissement}`. Les questions sont ensuite converties en `QuestionQCM` (`@Model` SwiftData, avec le suivi de Leitner).

### Erreurs

Toute erreur a la forme `{"code": "...", "message": "..."}`. Le `message` est en français et s'affiche tel quel. Les branchements se font sur `code`, jamais sur le message. Ces codes alimentent l'enum `GenerationError` du README.

| `code` | HTTP | Conduite côté app |
|---|---|---|
| `invalid_token` | 401 | jeton absent ou faux : renvoyer vers Réglages |
| `invalid_pdf` | 400 | le fichier n'est pas un PDF |
| `pdf_too_large` | 413 | PDF de plus de 20 Mo |
| `invalid_request` | 422 | paramètre invalide ou fichier manquant (bug côté app) |
| `rate_limited` | 429 | plus de 10 requêtes par minute : patienter |
| `quota_exceeded` | 429 | quota de l'IA épuisé : réessayer plus tard |
| `provider_overloaded` | 503 | IA surchargée : réessayer dans quelques minutes |
| `provider_unavailable` | 503 | serveur mal configuré |
| `generation_timeout` | 504 | génération trop longue : proposer de réessayer |
| `generation_failed` | 502 | échec de génération : proposer de réessayer |
| `internal_error` | 500 | erreur serveur imprévue |

Un code inconnu se traite comme une erreur générique, avec le `message` reçu. Une réponse non JSON (proxy, serveur arrêté) correspond à une erreur réseau.

### Comportement à connaître

- **Latence mesurée** : de 20 à 45 s pour un cours de 30 pages, de 10 à 30 questions. Régler `timeoutInterval` à **300 s** (pire cas de l'API : environ 4 min) et afficher une progression indéterminée.
- **Cache de l'API** : le même PDF avec le même `nb_questions` est servi instantanément, avec le même QCM. Réessayer après une coupure ne coûte donc rien si le serveur avait terminé.
- **Limite de requêtes** : 10 par minute, commune à tout le jeton.
- **`GET /health`** renvoie `{"status": "ok"}`, sans authentification : à utiliser pour un bouton « Tester la connexion » dans Réglages.

## Configuration

- **`Config/Secrets.xcconfig`** (ignoré par Git) fournit `API_BASE_URL` et `API_TOKEN` pour le Debug. Dans un `.xcconfig`, `//` démarre un commentaire : écrire `http:/$()/hote:8000`. Ces valeurs passent dans l'app par les clés de `Config/Info-Debug.plist` (`$(API_BASE_URL)`) et `ReglagesAPI` les lit dans `Bundle.main.infoDictionary`. Une variable absente arrive vide.
- **Keychain** (choix du README) : URL et jeton saisis dans Réglages, rangés dans le Keychain (`Keychain`, service `RevIA`, clés `api.url` et `api.jeton`). **La valeur du Keychain prime**, et celle du `.xcconfig` ne sert que de valeur initiale en Debug. `ReglagesAPI.configuration` vaut `nil` tant que l'adresse n'est pas valide (http ou https, avec un hôte) ou que le jeton manque.
- **Essai depuis le simulateur sans saisie** : passer les valeurs initiales en ligne de commande, par exemple `xcodebuild … API_BASE_URL=http://127.0.0.1:8765 API_TOKEN=<jeton jetable> build`.
- **Adresse de l'API en dev** :
  - simulateur : `http://127.0.0.1:8000` (il partage le réseau du Mac) ;
  - iPhone réel : `http://<nom-du-mac>.local:8000` plutôt qu'une IP, car ce nom est stable d'un réseau à l'autre.
- **ATS, en Debug uniquement** : `NSAppTransportSecurity` → `NSAllowsLocalNetworking = YES`, qui couvre les noms `.local`. **Vérifié le 2026-11-05 sur le simulateur** : `http://127.0.0.1` passe (GET et POST multipart), et passe même sans l'exception, car l'adresse de boucle locale n'est pas soumise à l'ATS. L'exception reste nécessaire pour `<nom-du-mac>.local` sur un iPhone (pas encore vérifié sur appareil). En Release, pas d'exception : l'API devra être servie en HTTPS.
- **iPhone réel** : `NSLocalNetworkUsageDescription` (texte en français) est nécessaire pour accéder au réseau local.

## Architecture et choix d'implémentation

- **Génération derrière un protocole** (`GenerateurQCM`), implémenté par `APIGenerateur`. Les ViewModels ne dépendent que du protocole, ce qui permet de les tester avec un faux générateur.
- **SwiftData** : `UE` 1-n `Cours` 1-n `QuestionQCM`, plus `SessionRevision` (voir le tableau du README). Les suppressions se font en cascade de l'UE vers ses cours et leurs questions. `StatutGeneration` (enum stockée sur `Cours`) : jamais générée, en cours, terminée, ou échec avec son `code` d'erreur.
- **Pas de régénération implicite** (README) : la génération ne part que d'une action explicite. Les questions sont enregistrées en SwiftData. Régénérer remplace les questions du cours, après confirmation.
- **Import** : `.fileImporter` pour les PDF (URL à accès sécurisé, puis copie dans le conteneur de l'app). Le scan passe par VisionKit, qui produit des images : **les assembler en PDF (PDFKit) avant l'envoi**, car l'API n'accepte que du PDF.
- **Leitner** : règles décidées par l'utilisateur.
  - 5 boîtes, avec des intervalles de **1, 2, 4, 8 et 16 jours** (boîtes 1 à 5), regroupés dans une seule constante de `Leitner.swift`.
  - Nouvelle question : boîte 1, révision le lendemain.
  - Bonne réponse : la question monte d'une boîte, et revient après l'intervalle de sa nouvelle boîte.
  - **Bonne réponse en boîte 5 : la question reste en boîte 5 et revient 16 jours plus tard.** Elle ne sort jamais de la révision.
  - Erreur, quelle que soit la boîte : retour en boîte 1, révision le lendemain.
  - Les dates se comptent en **jours calendaires** (`Calendar`, fuseau local, début de journée), pas en heures : une question est « à revoir » si le jour de sa prochaine révision est aujourd'hui ou passé. `FileDeRevision` alimente « À revoir aujourd'hui », toutes UE confondues.
- **Statistiques** par UE et par `theme`, avec Swift Charts. **Rappel quotidien** par notification locale (`UNUserNotificationCenter`).

## Tests

- Swift Testing (`import Testing`, `@Test`, `#expect`). Aucun test unitaire n'appelle le vrai serveur.
- `DecodageQCMTests` décode la fixture partagée, et vérifie aussi le décodage d'une erreur `{code, message}`.
- `APIGenerateur` se teste avec un `URLProtocol` simulé : forme de la requête multipart (`file`, `nb_questions`, `X-API-Token`), puis traduction de chaque code HTTP et de chaque `code` d'erreur.
- `LeitnerTests` couvre :
  - la montée de la boîte 1 à la boîte 5 (J+2, J+4, J+8, J+16) ;
  - le maintien en boîte 5 sur bonne réponse (J+16) ;
  - le retour en boîte 1 depuis n'importe quelle boîte (J+1) ;
  - une nouvelle question (boîte 1, J+1) ;
  - le calcul en jours calendaires : une réponse donnée à 23 h 59 et une donnée à 0 h 01 tombent bien sur des jours différents.
- Simulation du réseau : `RevIATests/Outils/URLProtocolSimule.swift`. Son état est partagé : toute suite qui l'utilise est `@Suite(.serialized)`. Les fixtures se chargent avec `fixture("nom")` (`RevIATests/Outils/Fixtures.swift`).
- Essai manuel de bout en bout : API lancée par `make dev` dans `../revia-api`, app sur le simulateur.
- **Essai du client sans appeler l'IA** : lancer l'API sur un autre port avec un jeton jetable passé en variable d'environnement (`API_TOKEN=… .venv/bin/uvicorn app.main:app --port 8765`, sans lire le `.env`), puis envoyer un fichier qui ne commence pas par `%PDF-`. Réponses attendues : `invalid_token` avec un mauvais jeton, `invalid_request` avec `nb_questions` à 31, `invalid_pdf` sinon, ce qui prouve que le multipart est bien lu. Arrêter le serveur ensuite.

## Conventions et façon de travailler

- **Langue** : français pour les identifiants métier, les commentaires, les textes d'interface et les messages de commit. Commits sous la forme « Ajout de … (#n) », **sans trailer `Co-Authored-By`**.
- **En-tête Xcode** en tête de chaque fichier Swift (`//  Fichier.swift`, `//  RevIA`), comme les fichiers existants.
- **Enchaînement des lots, sans attendre de validation** (demande de l'utilisateur) : annoncer le plan au début du lot, puis aller jusqu'à la livraison sur `main`. Une décision de produit prise par défaut est signalée dans la PR et dans le compte rendu à l'utilisateur.
- **Réponses** en français, terminées par une section « En résumé » de 3 à 5 puces.
- **Circuit Git** : même circuit que `revia-api`. Une issue, une branche `<n°>-<slug>` depuis `dev`, une PR vers `dev` (« Refs #n »), puis une PR `dev` → `main` (« Livraison de dev sur main : … », « Closes #n »), avec des merge commits. **Claude merge les PR** (à la demande de l'utilisateur), une fois la compilation et les tests au vert.
- **Pas de CI pour l'instant** : à rediscuter une fois le client de l'API et ses tests en place.
