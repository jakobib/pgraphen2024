---
title: "Property-Graphen: eine kurze Einführung"
lang: de
authors:
  - name: Jakob Voß
    affiliation: Verbundzentrale des GBV (VZG)
#bibliography: references.bib
---

*VORLÄUFIGER ARTIKEL-ENTWURF*

Zu den Tätigkeiten der Stabstelle Forschung und Entwicklung der VZG gehört auch
das Ausprobieren und Evaluieren neuer Verfahren und Techniken. So kommt es dass
ich mich seit Anfang 2024, angeregt durch einen Anwendungsfall im Projekt
NFDI4Objects, verstärkt mit so genannten **Property-Graphen** zur
Strukturierung und Verarbeitung von (Meta)daten beschäftige. 

Property-Graphen (oft auch als Labeled Property Graphen bezeichnet) bilden ein
Datenbankmodell, das unter die so genannten NoSQL-Datenbanken und noch
spezieller unter die Graphdatenbanken fällt. Hierbei werden Daten nicht wie bei
SQL in Form von Tabellen sondern in Form von Graphen aus Knoten gespeichert,
die durch Kanten miteinander verbunden sind. Eine Besonderheit von
Property-Graphen ist, dass sowohl Knoten als auch Kanten mit Eigenschaften
versehen werden können.

## Beispiel

Zur Veranschaulichung soll folgende Sammlung einiger Charaktere, Beziehungen
und Eigenschaften aus dem Star-Wars-Universum dienen: Padmé, Anakin und Luke
sind Personen unterschiedlichen Geschlechts und R2D2 ist ein Roboter. In
Episode I gehört R2D2 zu Padmé, die ihn in Episode II Anakin zu ihrer
gemeinsamen Hochzeit schenkt, und in Episode IV gelangt der Roboter zu Luke,
der in Episode III als Kind von Padmé und Anakin geboren wurde.

Diese Informationen lassen sich in einem Property-Graphen mit Charakteren als
Knoten und ihren Beziehungen als Kanten modellieren. @lst-pg zeigt die
Kodierung des Graphen im **PG Format**, das ich derzeit zusammen mit den
Wissenschaftler Hirokazu Chiba, Ryota Yamanaka, und Shota Matsumoto als
Austauschformat für Property-Graphen entwickle. In dem Beispiel entsprechen die
Namen der Charaktere den Node-Identifiern und ihr Typ den Node-Labels . Das
Geschlecht und die jeweilige Episode sind als Eigenschaften den Knoten und
Kanten zugeordnet. Kanten haben ebenfalls ein Label mit der Beziehungsart und
sie können gerichtet (`->`) oder ungerichtet (`--`) sein.

```{#lst-pg .pg lst-cap="Beispiel-Graph im PG Format"}
# Knoten mit Knoten-Typ (Label) und Eigenschaften
Padmé  :person  gender:female
Anakin :person  gender:male                 
Luke   :person  gender:male                 
R2D2   :robot              
   
# Kanten mit Kanten-Typ (Label) und Eigenschaften
Padmé  -> R2D2   :owns      episode:1
Padmé  -- Anakin :marriage  episode:2
Anakin -> R2D2   :owns      episode:2    
Anakin -> Luke   :parent    episode:3
Padmé  -> Luke   :parent    episode:3 
Luke   -> R2D2   :owns      episode:4
```

Der Graph kann auf verschiedene Weise gespeichert und visualisiert werden.
@fig-image zeigt eine mögliche Darstellung ohne Eigenschaften. Mit Knoten,
Kanten mit Richtungen, Labels und Eigenschaften sind schon alle Elemente von
Property-Graphen aufgezählt. Je nach konkretem Datenformat und Datenbanksystem
können Labels und Eigenschaften auch mehrere Werte annehmen und verschiedene
Datentypen annehmen.

![](star-wars-blitzboard.png){#fig-image fig-cap="Visualisierung des Beispiel-Graphen"}


## Datenbanken

[Neo4J]: https://neo4j.com/
[Kùzu]: https://kuzudb.com/
[Memgraph]: https://memgraph.com/
[FalkorDB]: https://www.falkordb.com/
[Vendor Lock-In]: https://it-in-bibliotheken.de/management.html#vendor-lock-in
[Cypher]: https://opencypher.org/

Etabliert wurden Property-Graphen insbesondere durch das
Datenbankmanagementsystem (DBMS) [Neo4J]. Die Open-Source-Software war lange
Marktführer in diesem Bereich und setze dort Standards wie die Abfragesprache
Cypher (Siehe @lst-cypher und @lst-match), die inzwischen auch von anderen
Anbietern unterstützt wird. Dazu zählen derzeit die Open-Source-Systeme [Kùzu],
[Memgraph] und [FalkorDB], so dass wie bei Relationalen DBMS (RDBMS) die Gefahr
für [Vendor Lock-In] gering ist. Im letzten Update des SQL-Standard (SQL:2023)
wurde zumdem unter dem Namen SQL/PGQ eine Teilmenge von Cypher als
Abfragesprache für Property-Graphen in SQL-Datenbanken definiert, es ist also
davon auszugehen, dass in Zukunft einige RDBMS Property-Graphen auch direkt
unterstützen.

Der Beispielgraph kann in Neo4J oder in einer damit kompatiblen Datenbank mit
folgenden Cypher-Statements angelegt werden (@lst-cypher). Da Knoten-Identifier
in der Datenbank rein intern sind, sind die Namen zusätzlich als Eigenschaft
`name` angegeben. Außerdem unterstützt Cypher nur gerichtete Kanten, daher ist
die Beziehung zwischen Padmé und Anakin weggelassen.

```{#lst-cypher .cypher lst-cap="Beispiel-Graph als Cypher-Statements"}
CREATE (Anakin:person {gender:"male", name:"Anakin"})
CREATE (Luke:person {gender:"male", name:"Luke"})
CREATE (Padmé:person {gender:"female", name:"Padmé"})
CREATE (R2D2:robot {name:"R2D2"})
CREATE (Padmé)-[:owns {episode:1}]->(R2D2)
CREATE (Anakin)-[:owns {episode:2}]->(R2D2)
CREATE (Anakin)-[:parent {episode:3}]->(Luke)
CREATE (Padmé)-[:parent {episode:3}]->(Luke)
CREATE (Luke)-[:owns {episode:4}]->(R2D2)
```

Nun können die Daten mit Cypher-Abfragen ausgewertet werden (@lst-match):

```{#lst-match .cypher lst-cap="Abfragen in Cypher-Syntax"}
# Wer sind die Eltern der Person mit dem Namen Luke?
MATCH (p)-[:parent]->(:person {name:"Luke"}) RETURN p

# Wie heißen die Besitzer von R2D2 ab Episode 2?
MATCH (p)-[e:owns]->({name:"R2D2"}) WHERE e.episode >= 2 RETURN p.name
```

Wie bei allen Datenbanken können die Abfrageergebnisse natürlich nur so gut
sein wie die Datenbasis: so würde eine Frage nach den Kindern von Anakin nur
Luke ergeben, weil seine Zwillingsschwester Leia im Beispiel-Graph fehlt.
Grundsätzlich stellt die Modellierung von Property-Graphen aber ein
leistungsfähiges und flexibels Werkzeug vor allem für semi-strukturierte und
verknüpfte Daten da. Im Projekt NFDI4Objects haben wir uns deshalb dazu
entschieden die Zusammenführung heterogener Daten aus verschiedenene Quellen in
einem Property-Graphen durchzuführen.


## Vergleich mit RDF

Zu den Graphdatenbanken gehören auch die so genannten **Triple-Stores**, in
denen Daten dem RDF-Datenmodell nach gespeichert werden.  Da RDF und die damit
verbundenen Konzepte von Linked Data und Semantic bereits seit Jahrzehnten
propagiert werden, ist die Frage berechtigt, ob nicht mal wieder mit
Property-Graphen als neuem Trend das Rad neu erfunden wird. Tatsächlich sind
RDF und Property Graphen aus unterschiedlicher Motivation heraus entstanden und
haben daher verschiedene Schwerpunkte und Einsatzzwecke.

RDF ist grundsätzlich ein Austauschformat zum Publizieren und Zusammenführen
von Daten.  Grundstein bilden dabei die übergreifend nutzbaren URIs zur
weltweit eindeutigen Identifizierung von Konzepten. Bei Property-Graphen geht
es dagegen primär um die effiziente Speicherung und Auswertung von vernetzen
Daten in einer abgeschlossenen Datenbank.

...

Rein formal bestehen Daten auch im RDF-Modell aus Knoten und Kanten, wobei
Knoten als "Ressourcen" und Kanten als "Triples" bezeichnet werden. Eine
Entsprechung zu Eigenschaften gibt es in RDF nicht, Knoten haben keine
Knoten-Label und Kanten-Label werden "Properties" genannt. Die Rolle der
fehlenden Knoten-Label und Knoten-Eigenschaften übernehmen in RDF zusätzliche
Kanten (die sich allerdings nicht von "normalen" Kanten unterscheiden lassen).
@lst-ttl zeigt den Beispiel-Graphen in RDF-Turtle-Syntax und @lst-sparql der
ersten Cypher-Abfrage in @lst-match entsprechende Abfrage in der RDF-eigenen
Abfragesprache SPARQL.

```{#lst-ttl .ttlr lst-cap="Beispiel-Graph in RDF/Turtle (ohne Kanten-Eigenschaften)"}
<Padmé>  a <person> ; <gender> "female" ; <name> "Padmé" .
<Anakin> a <person> ; <gender> "male" ; <name> "Anakin" .
<Luke>   a <person> ; <gender> "male" ; <name> "Luke"  .
<R2D2>   a <robot> ; <name> "R2D2" .

<Padmé>  <owns> <R2D2> .
<Anakin> <owns> <R2D2> .
<Anakin> <parent> <Luke> .
<Padmé> <parent> <Luke> .
<Luke>  <owns> <R2D2> .
```

```{#lst-sparql .sparql lst-cap="SPARQL-Abfrage"}
SELECT ?p { ?p <parent> [ a <person> ; <name> "Luke" ] }
```

Die grundsätzliche Beschränkung in RDF ... hat zu verschiedenen Erweiterungen geführt
von denen RDF-star ... Die dazu gehörigen Standards befinden sich allerdings noch
in Bearbeitung ... im aktuellen Entwurf von RDF/Turtle 1.2 könnten Kanten...

```ttl
<Padmé>  <owns> <R2D2>   {| <episode> 1 |} .
<Anakin> <owns> <R2D2>   {| <episode> 2 |} .   
<Anakin> <parent> <Luke> {| <episode> 3 |} .
<Padmé> <parent> <Luke>  {| <episode> 3 |} .
<Luke>  <owns> <R2D2>    {| <episode> 4 |} .
```

SPARQL 1.2 (Working draft!)

```sparql
SELECT ?name {  
  ?r2d2 <name> "R2D2"
  BIND( << ?p <owns> ?r2d2 >> AS ?e )
  ?p <name> ?name
  FILTER ( e.episode >= 2 )
}
```

 RDF | Property Graphen 
-----|-----------------
Etablierte Standards des W3C | Laufende Standardisierung
URIs als globale Identifier | -
Zusammenführung aus unterschiedlichen Quellen | 
... |
Abfragesprache SPARQL | Abfragesprache Cypher
Schemasprachen ... | ...

PG und RDF lassen sich zumindest einfacher aufeinander abbilden als Formate
in hierarchischen oder feldbasierten Formaten wie MARC, PICA, XML.

- Triples
- Können integriert werden
- Benötigen Ontologien

Vor- und Nachteile von Property Graphen im Vergleich zu RDF:

- Flexibler: keine Ontologien notwendig
- Abfragesprache Cypher etwas einfacher als SPARQL
- Nicht so einfach mit externen Daten integriertbar

Semantik (Inference-Regeln).

Die Praxis hat allerdings gezeigt, dass Ontologien allein zur Sicherstellung 
von Datenqualität nicht ausreichen sondern zusätzliche

Schema (Shacl/SheX)

Nicht zuletzt trägt die Herkunft und Stärke von RDF aus der Datenintegration
dazu bei, dass RDF-Modelle tendenziell eher projektübergreifend und nachnutzbar
angelegt werden. Dieser Vorteil birgt in der Praxis allerdings die auch die
Gefahr von langwierigen Prozessen und theoretischen Lösungen, die
möglichwerweise an der Praxis vorbeigehen.

PG: Nur innerhalb der eigenen Datenbank konsistentes, abgeschlossenes Modell
RDF: offen (Open World Assumption)

## Property Graphen an der VZG

- NFDI4Objects
- PG format
- pgraphs: Werkzeug zur Konvertierun

## Zusammenfassung

- Flexibler als RDF
- Standardisierung in SQL. Bisher Oracle
- Abfragesprache Cypher

