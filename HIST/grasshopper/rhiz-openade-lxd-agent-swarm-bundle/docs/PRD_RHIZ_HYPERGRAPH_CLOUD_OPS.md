# PRD

## RHIZ Hypergraph Cloud Ops Control Plane

Version: 0.1  
Date: 2026-04-03  
Statut: draft de synthese produit  
Base documentaire: corpus projet consulte jusqu'au 2026-04-02
Auteur: kobalt | kobalt-σ

## 1. Resume executif

Le projet RHIZ decrit deja les briques d'un systeme coherent mais distribue:

- un plan de controle contractuel et bastion (`/operator/rhiz-ueht`)
- une projection UI de l'architecture (`/cloud-compute`, `/rhiz/uniphi`, `/rhiz/PHI|OS`)
- une trame d'orchestration infra et reseau (`/ops`)
- une couche d'hypergraph awareness, de compute distribue, de MCP et d'agents (`/hypergraph`, `/rhiz/polyfractal-ontology`, `/rhiz/fabrik`)

Le besoin produit n'est plus de creer une nouvelle pile isolee, mais d'unifier ces surfaces en un seul produit operable: un control plane hypergraph-aware qui permet de comprendre, configurer, projeter, enroler, superviser et promouvoir l'etat du systeme distribue sans dupliquer les autorites existantes.

Ce PRD propose de productiser cette convergence sous un nom de travail: `RHIZ Hypergraph Cloud Ops Control Plane`.

## 2. Contexte

### 2.1 Ce que le projet est deja

Le corpus indique une architecture polyfractal structuree par cinq domaines stables:

- logique
- business intelligence
- hypergraph awareness
- orchestration
- trust

Le systeme est organise en plans:

- control-plane
- directive-plane
- analysis-plane
- simulation-plane
- host-plane
- compute-plane
- storage-plane
- awareness-plane

Les surfaces actuelles les plus structurantes sont:

- `akatsuki-singularity` comme source canonique des contrats, directives, handshake et remote-config
- `factory-kobalt-sigma` comme surface de chat, BI, provider routing et coupling UI/agents
- `rhiz-ueth` comme bastion operateur, autorite de publication et point de handshake
- `cloud-compute` comme couche de projection UI des directives `ops`
- `hypergraph` comme couche awareness, simulation, agents, graph services et workloads distribues

### 2.2 Ce que le projet n'est pas encore

Le corpus decrit aussi des limites nettes:

- `/cloud-compute` est aujourd'hui une projection et une interface de lecture, pas un moteur de mutation autonome
- `/hypergraph` n'est pas decrit comme le repo d'autorite de deploiement
- plusieurs composants sont "documentation-first", "manifest-first" ou "scaffolded presets"
- les gestes critiques doivent rester gates par trust, handshake, signature et approbation operateur

Le gap produit principal est donc l'absence d'une experience unifiee qui fasse converger:

- le contrat
- la topologie
- la projection hypergraphique
- l'enrollement des noeuds
- la supervision
- la promotion vers les environnements

## 3. Probleme a resoudre

Aujourd'hui, un operateur ou un architecte doit naviguer entre plusieurs racines pour repondre a une question simple:

- quelle est l'autorite de verite pour tel service
- quel noeud porte quel role
- quel est l'etat de sante et de confiance avant promotion
- quel bundle doit etre regenere apres un changement
- quelle partie du systeme peut agir automatiquement et quelle partie doit rester advisory

Cette fragmentation produit:

- de la derive entre projection UI et contrats reels
- de la duplication potentielle entre `/ops`, `/cloud-compute`, `/hypergraph` et `/operator/rhiz-ueht`
- un onboarding difficile des field nodes et hypernodes
- une observabilite inegale sur le lineage, les fallbacks providers et les gates de promotion
- une difficulte a transformer le savoir architectural du projet en operation quotidienne

## 4. Vision produit

Construire une surface unifiee qui traite RHIZ comme un `hypergraph-aware operating fabric`:

- le contrat et la confiance vivent dans le control-plane
- les directives et invariants vivent dans le directive-plane
- la BI et les preuves vivent dans l'analysis-plane
- la projection de topologie et de subsets vit dans l'awareness-plane
- l'execution et le placement vivent dans le compute-plane et le host-plane

Le produit doit permettre a un operateur d'aller de `comprehension -> selection -> validation -> emission -> promotion -> supervision -> rollback` sans casser la separation des autorites deja en place.

## 5. Hypothese de produit

Le produit cible de V1 est:

- une experience operateur unifiee exposee principalement via `Uniphi /cloud-compute` et son `secondary composer`
- alimentee par les contrats du bastion `rhiz-ueth`
- projetee depuis les directives `ops` et l'ontologie polyfractale
- connectee aux hypernodes, services, pools et routes du tissu hypergraphique

Nom de la feature centrale de V1:

- `Master Generative Flow Composer`

Cette feature devient la porte d'entree operateur du control plane.

## 6. Utilisateurs cibles

### 6.1 Operateur bastion

Responsable de:

- valider les contrats
- approuver les promotions
- superviser le trust gate
- piloter rollback et release

### 6.2 Ingenieur infra / ops

Responsable de:

- WireGuard, Ceph, libvirt, LXD, Docker Swarm
- placement CPU/GPU/storage
- enrollment gateway
- bootstrap des hosts et guests

### 6.3 Mainteneur hypergraph / AI

Responsable de:

- graph services
- provider routing
- MCP et agents
- workloads d'inference, de recherche et de simulation

### 6.4 Field operator

Responsable de:

- factau-rhiz
- eliosys-rhiz
- services hardware-near
- telemetry, GPIO, vision, SDR, monitoring de terrain

### 6.5 Analyste / architecte produit

Responsable de:

- lecture des signaux BI
- interpretation des subsets hypergraphiques
- analyse des invariants et des risques de promotion

## 7. Jobs To Be Done

1. Quand je prepare un changement, je veux voir la topologie active, les dependances et les invariants pour savoir si le systeme peut accepter la mutation.
2. Quand j'enrole un nouveau noeud, je veux hydrater son remote-config, faire le handshake signe et obtenir un runtime local sans recreer une seconde autorite de controle.
3. Quand j'explore une composition cloud-compute, je veux filtrer par strates de compute, profils, knowledge lenses et invariant gates pour projeter un subset deployable du hypergraph.
4. Quand je route un workload IA, je veux privilegier le local-first avec fallback traceable vers un provider distant.
5. Quand je promeus vers un edge public ou un environnement TLS, je veux des gates explicites sur health quorum, lineage, secrets et rollback.
6. Quand j'observe le systeme, je veux une preuve lisible: qui a decide, sur quelle evidence, avec quel provider, sur quel noeud, et avec quelle possibilite de retour arriere.

## 8. Objectifs produit

### 8.1 Objectifs business / programme

- transformer le corpus architectural RHIZ en surface operable
- reduire le temps de comprehension et de promotion d'un changement distribue
- rendre portable le tissu RHIZ vers de nouveaux noeuds, pods et projets externes
- unifier la gouvernance entre hypergraph, cloud-compute et ops

### 8.2 Objectifs utilisateurs

- une seule experience pour lire et agir
- moins de drift entre contrat, projection et execution
- une traque complete du lineage et des fallbacks
- un onboarding field node ou hypernode plus court et plus sur

### 8.3 Non-objectifs de V1

- automatiser des operations destructives sans approbation explicite
- faire de `/cloud-compute` un orchestrateur autonome hors contrat
- remplacer `/operator/rhiz-ueht` comme autorite du remote-config
- convertir `.phi` en namespace public ICANN
- unifier tout le codebase en un monorepo unique

## 9. Portee

### 9.1 In scope V1

- tableau de bord unifie des plans de controle, compute, storage, awareness et trust
- `Master Generative Flow Composer` avec selection:
  - composer variant
  - compute stratum
  - psychometric profile
  - knowledge lens
  - invariant gate
  - generative card
- projection d'un subset du hypergraph en enveloppes exploitables
- lecture centralisee des catalogues:
  - schema
  - remote-config
  - directives
  - endpoints
  - monitoring
  - setup
  - model catalog
  - health
- enrollment guide et semi-automation pour hypernodes et field nodes
- BI operateur explicite:
  - threshold score
  - subset density
  - promotion risk
  - trust state
- health quorum avant promotion
- traces de provider routing et de fallback
- generation ou synchronisation des artefacts de sortie:
  - runtime config
  - gateway remote-config hints
  - nginx HTTP/TLS configs
  - CI/CD scaffold
  - release bundle / handoff package

### 9.2 In scope V2

- suggestions de placement multi-pool CPU/GPU/storage
- orchestration guidee de workloads externes type `niurk-42 -> ark-rhiz -> niurk-43`
- federation de projets externes dans le control plane
- politique de promotion plus dynamique basee sur quorums, cost pressure et evidence freshness

### 9.3 Out of scope

- orchestration full-autonomous sans trust gate
- gestion complete des secrets en dehors des references vers un backend de secrets
- automation de registry Nomulus ou SSO jusqu'en production sans arbitrage operateur
- support generique de tout hardware exotique en V1

## 10. Exigences fonctionnelles

### FR1. Catalogue d'autorite

Le produit doit exposer clairement:

- quelle surface est source d'autorite
- quelle surface est projection
- quelle surface est execution
- quelle surface est advisory

Exemples attendus:

- `/operator/rhiz-ueht` = autorite de remote-config, directives, endpoints, handshake
- `/ops` = enrollment edge et automation infra
- `/cloud-compute` = projection UI
- `/hypergraph` = fabric awareness, graph services, agents, workloads

### FR2. Projection hypergraph-aware

Le produit doit projeter un subset du systeme a partir:

- des directives `ops`
- de l'ontologie polyfractale
- des catalogues du bastion
- des etats de noeuds et de services

La projection doit rendre explicites:

- layers
- planes
- profiles
- services
- nodes
- pools
- invariants
- rules commutatives et combination rules

### FR3. Experience `Master Generative Flow Composer`

L'utilisateur doit pouvoir:

- selectionner une variante, une strate de compute et un profil
- filtrer par knowledge lens et invariant gate
- visualiser le subset cible du hypergraph
- voir les impacts attendus sur runtime, gateway, CI/CD et operator lanes
- produire une enveloppe deployable ou advisory

### FR4. Enrollment et trust bootstrap

Le produit doit guider et tracer:

- la generation d'un token ephemere
- l'hydratation des catalogues publics
- le handshake signe
- la generation d'un `runtime.env` local
- le callback optionnel vers l'enrollment edge `/ops`

Les caches attendus doivent etre visibles ou auditablement references:

- schema
- remote-config
- directives
- public-endpoints
- monitoring
- remote-management
- setup-plan
- model-catalog
- health
- handshake request/response
- runtime env
- state

### FR5. Observabilite operateur

Le produit doit afficher:

- health quorum control-plane
- disponibilite d'au moins une route provider
- fraicheur des preuves BI
- lineage des decisions et recommandations
- ordered routing trace des fallbacks providers
- heartbeat et identite stable des hypernodes

### FR6. Placement et ressources

Le produit doit representer les plans de ressources:

- hosts Fedora
- VMs Ubuntu
- cluster LXD
- cluster Swarm
- pools CPU
- pools GPU
- pools storage
- field nodes hardware-near

Le produit doit faire apparaitre les contraintes de placement:

- manager-only
- GPU-labeled nodes
- durable volumes
- queue/API ingress
- overlay access
- SSO et audit logging

### FR7. Promotion et rollback

Avant toute promotion, le produit doit verifier:

- validite schema
- invariants critiques
- secret refs valides
- health quorum
- traceabilite operateur
- existence d'un rollback path

Le produit doit distinguer trois sorties:

- advisory only
- ready for approval
- approved for promotion

### FR8. Ouverture communautaire via hypernode

Le produit doit supporter un mode d'adhesion simplifie d'un hypernode open source:

- generation ou recuperation d'une identite stable
- handshake vers Factory / Hypergraph
- enregistrement du noeud
- heartbeats periodiques
- remontees minimales de metriques

## 11. Exigences non fonctionnelles

### NFR1. Truthfulness et auditabilite

- toute decision doit etre attribuable et falsifiable
- tout fallback provider doit etre trace
- toute action liee a BI sans lineage suffisant doit rester advisory

### NFR2. Consent et bounded autonomy

- aucune promotion a blast radius non trivial sans trust gate
- toute action destructive exige approbation explicite ou signature equivalente

### NFR3. Reversibilite

- tout flux de promotion doit inclure un chemin de rollback
- durable artifacts et caches ephemeres doivent rester separes

### NFR4. Portabilite

- les bundles et profils doivent rester exportables vers d'autres serveurs ou bastions
- la projection UI ne doit pas creer de nouveaux champs de contrat non versionnes

### NFR5. Local-first compute

- priorite aux providers locaux quand la sante et les politiques le permettent
- fallback distant autorise mais observable

### NFR6. Performance operateur

Objectifs initiaux:

- chargement du tableau de bord principal < 3 s sur cache chaud
- actualisation health/provider/quorum <= 60 s
- projection d'un subset compose <= 5 s
- rendu d'un bundle de projection <= 10 s

## 12. Architecture produit cible

### 12.1 Planes

- `Control plane`: contrats, schema, remote-config, handshake, endpoint catalog
- `Directive plane`: politiques, benchmarks, workflows, gating rules
- `Analysis plane`: BI, scores, recommandations, monitoring summaries
- `Awareness plane`: hypergraph kernel, quorum routing, ontology projection
- `Host plane`: bootstrap hosts, overlay, swarm lifecycle, secret delivery
- `Compute plane`: inference locale/distante, agents, MCP, research workers
- `Storage plane`: artifacts, caches, lineage, telemetry history

### 12.2 Noeuds de reference

- `niurk-21` = bastion operateur et autorite de gouvernance
- `niurk-23` = surface applicative et runtime exosys-k
- `niurk-43` = hypergraph control hypernode et awareness index
- `ark-rhiz` = host GPU / Ceph / libvirt / cloud-compute
- `factau-rhiz` = field pod, monitoring, SDR, microcontroller control
- `eliosys-rhiz` = edge hypernode borne pour ingress, vision, GPIO, SDR
- `rik-water-gpu` = relay GPU LXD reachable via bastion

### 12.3 Surfaces UI

- `Uniphi /cloud-compute` = surface operateur principale
- `Uniphi /cloud-compute/compose` = composer de subset et d'emission
- `PHI|OS` = couche manifeste et design/orchestration
- `Factory / Kobalt Sigma` = surface BI, chat, provider routing et etat assistant

## 13. Donnees et objets coeur

Le produit doit manipuler comme objets de premier rang:

- plane
- stack
- module
- service
- pool
- signal
- directive
- invariant
- state-space
- archetype
- node
- runtime profile
- handshake
- health quorum
- routing trace
- deployment envelope

## 14. KPI et succes

### 14.1 KPI adoption

- taux de promotions preparees depuis la surface unifiee
- nombre de noeuds enroles via le flux normalise
- nombre d'equipes ou projets externes raccordes au control plane

### 14.2 KPI operations

- temps median de comprehension d'un impact de changement
- temps median d'enrollment d'un node
- temps median de regeneration du bundle `/cloud-compute`
- taux de promotions bloquees a juste titre par les invariants
- temps median de rollback

### 14.3 KPI trust / quality

- couverture lineage sur recommandations BI
- couverture routing trace sur les reponses modeles
- taux de drift detecte entre schema et consommateurs
- pourcentage de promotions avec quorum vert complet

## 15. Roadmap proposee

### Phase 0. Consolidation du contrat

- figer la carte des autorites
- versionner clairement les schemas consommes
- exposer les statuts `authoritative`, `projection`, `execution`, `advisory`

### Phase 1. Surface unifiee read-mostly

- livrer le tableau de bord central
- brancher les catalogues bastion
- afficher topology, planes, pools, services, health et lineage
- regenerer `/cloud-compute/generated/architecture-services.bundle.json` depuis les directives

### Phase 2. Master Generative Flow Composer

- activer les filtres variant/stratum/profile/lens/invariant/card
- produire des subsets hypergraphiques lisibles
- emettre des enveloppes de runtime, gateway et CI/CD

### Phase 3. Enrollment et field ops

- industrialiser le bootstrap ephemere
- outiller `factau-rhiz`, `eliosys-rhiz` et les hypernodes open source
- unifier health, monitoring et caches de handshake

### Phase 4. Promotion guidee

- brancher approval, TLS promotion, gateway sync, bundle packaging
- afficher readiness, risk score et rollback path

### Phase 5. External project bridging

- supporter les flux de projection externe type BigPan / niurk-42
- lier workload externe, training GPU et awareness-plane sous gouvernance centrale

## 16. Risques principaux

### R1. Multiplication des sources de verite

Risque:
- duplication du remote-config entre bastion, ops, cloud-compute et hypergraph

Mitigation:
- imposer une carte d'autorite explicite et visible dans l'UI

### R2. Projection stale

Risque:
- `/cloud-compute` affiche un etat obsolete si regenere avant mise a jour des directives/contrats

Mitigation:
- imposer l'ordre `directive -> bastion bundle -> projection cloud-compute`

### R3. Automation trop ambitieuse

Risque:
- tentative d'autonomie non bornee sur des actions de prod

Mitigation:
- gates critiques, advisory-first, operator approval, trace d'audit

### R4. Drift d'identite des noeuds

Risque:
- duplication de noeuds ou collapse memoire/awareness

Mitigation:
- identite stable obligatoire et registry visible

### R5. Dette de scaffolding

Risque:
- confusion entre composants reellement operables et presets documentaires

Mitigation:
- matrice de maturite par composant dans la surface produit

## 17. Questions ouvertes

1. Quelle surface doit devenir la porte d'entree officielle: `Uniphi`, `Factory`, ou une facade dediee adossee au bastion?
2. Quel sous-ensemble des mutations peut etre autorise en self-service avant approbation humaine?
3. Comment versionner la projection `/cloud-compute` pour garantir sa coherence avec le schema publie par le bastion?
4. Quel est le premier parcours prioritaire a productiser entre:
   - enrollment d'un field node
   - promotion d'un subset compose
   - supervision des providers et pools
5. Comment exposer les concepts psychometriques et archetypaux sans degrader la lisibilite operateur?

## 18. Definition of Done V1

La V1 est consideree livree si:

- un operateur peut ouvrir une seule surface et voir les plans, noeuds, pools, services et catalogues d'autorite
- le composer peut produire un subset hypergraphique exploitable et expliquer ses invariants
- un flux d'enrollment type `factau-rhiz` ou hypernode open source est guide de bout en bout
- la promotion reste gatee par quorum, lineage et approbation
- les traces provider et les preuves BI sont visibles
- la regeneration du bundle cloud-compute suit le contrat sans duplication de source de verite

## 19. Sources principales consultees

- `/rhiz/GENESIS.md`
- `/rhiz/arch/README.md`
- `/rhiz/arch/directives/master-generative-flow-composer.md`
- `/rhiz/arch/runtime/arch-runtime.config.json`
- `/rhiz/arch/runtime/local-gateway.remote-config.json`
- `/rhiz/polyfractal-ontology/README.md`
- `/rhiz/polyfractal-ontology/ontology/ontology.core.json`
- `/rhiz/polyfractal-ontology/architecture/topology.json`
- `/rhiz/polyfractal-ontology/architecture/module-fabric.json`
- `/rhiz/polyfractal-ontology/ethos/ethos.core.json`
- `/rhiz/polyfractal-ontology/invariants/system-invariants.json`
- `/rhiz/polyfractal-ontology/logic/reasoning-lattice.json`
- `/rhiz/polyfractal-ontology/profiles/distributed-runtime.profile.json`
- `/rhiz/ontology/polyfractal-data-intertwinning-technical-guide.md`
- `/rhiz/ontology/rhiz-ueth-factau-porting-review.md`
- `/rhiz/ontology/directives/rhiz-ueth-factau-porting.directive.json`
- `/rhiz/ontology/directives/niurk-42-bigpan-niurk-43-emergence.directive.json`
- `/rhiz/fabrik/hypernode/README.md`
- `/rhiz/fabrik/hypernode/runner.mjs`
- `/rhiz/uniphi/README.md`
- `/rhiz/PHI|OS/README.md`
- `/rhiz/paradigm/docs/ARCHITECTURE.md`
- `/cloud-compute/README.md`
- `/cloud-compute/build_bundle.py`
- `/cloud-compute/generated/architecture-services.bundle.json`
- `/ops/README.md`
- `/ops/docs/ARCHITECTURE-LAYERS.md`
- `/ops/docs/CLOUD-COMPUTE.md`
- `/ops/docs/GATEWAY-ENROLLMENT.md`
- `/ops/docs/ROLLBACK-AND-REDEPLOY.md`
- `/ops/docs/POOLS-AND-PLACEMENT.md`
- `/ops/modules/73-gateway-remote-config.sh`
- `/operator/rhiz-ueht/README.md`
- `/hypergraph/hypergraph_meta_cluster_bundle/README.md`
- `/hypergraph/hypergraph_meta_cluster_bundle/META_CLUSTER_ARCHITECTURE.md`
- `/hypergraph/hypergraph_meta_cluster_bundle/DEPLOYMENT.md`

## 20. Note de synthese

Ce PRD ne traite pas RHIZ comme un simple produit SaaS, ni comme un simple bundle d'infra. Il le traite comme un systeme de gouvernance operatoire ou le produit principal est la capacite a projeter, expliquer et gouverner un tissu distribue hypergraph-aware sans perdre:

- la verite du contrat
- la visibilite des preuves
- la reversibilite des actions
- la separation entre projection, autorite et execution
