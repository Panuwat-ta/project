# Wiki Operating Guide — Scam Image Detection

## Project Context

This wiki serves as the persistent knowledge base for the **Scam Image Detection** project, developed by Software Engineering students at RMUTL (Academic Year 2/2568).

> **CRITICAL DOMAIN RESTRICTION:** Do NOT conflate this project with standard "fake bank slip detection." This project aims to detect scam-related image manipulations in a broader context (e.g., romance scams, forged documents, AI-generated synthetic images), not just bank slips.

---

## Folder Structure

```
wiki/
  AGENTS.md          <- This file: The operating guide and schema for LLM agents.
  index.md           <- The master catalog of all pages (must be updated on every ingest).
  log.md             <- The chronological operation log (append-only).
  howto.md           <- User-facing guide on how to interact with the wiki and the LLM.
  overview.md        <- The high-level synthesis of the entire project.

  concepts/          <- Core concepts and techniques
    multi-layer-analysis.md
    risk-scoring.md
    explainable-ai.md
    ai-model-segformer.md
    Semantic Segmentation-technique.md

  architecture/      <- System design and structural components
    system-architecture.md
    mobile-app.md
    backend-api.md
    ai-inference-service.md
    database-schema.md
    external-integrations.md

  entities/          <- Named system actors, components, and services
    actors.md
    tech-stack.md

  decisions/         <- Engineering trade-offs and technology choices
    technology-choices.md

  requirements/      <- Functional and non-functional requirements, KPIs
    objectives-kpis.md
    functional-requirements.md
    non-functional-requirements.md

  planning/          <- Scope, tasks, timeline, and team info
    project-scope.md
    team.md
```

---

## Page Convention

### Frontmatter (YAML)

Every page MUST begin with the following YAML frontmatter:

```yaml
---
title: "Page Title (Thai preferred)"
category: concepts | architecture | entities | decisions | requirements | planning
tags: [tag1, tag2]
sources: [relative/path/to/source.md]
updated: YYYY-MM-DD
---
```

### Cross-references

- Use Obsidian-style wikilinks: `[[page-name]]` or `[[page-name|Display Text]]`.
- Any concept mentioned for the first time in a document MUST be linked to its dedicated page.
- Every page MUST contain a "Related Pages" (หน้าที่เกี่ยวข้อง) section at the very bottom.

### Page Structure

1. A brief, one-sentence summary immediately following the frontmatter.
2. Main content organized logically with H2/H3 headers.
3. A "Key Points" or "Summary" (ประเด็นสำคัญ) section.
4. A "Related Pages" (หน้าที่เกี่ยวข้อง) section.

---

## LLM Agent Workflow

### 1. Ingesting New Documents

When instructed to ingest a document from `Document/`, `design/`, or elsewhere:

1. Read the entire raw source document.
2. Identify core concepts, entities, decisions, and key information.
3. Create or update the relevant wiki pages in the appropriate directories.
4. Update `index.md` to reflect any newly created pages.
5. Append a new entry to `log.md` in the exact format: `## [YYYY-MM-DD] ingest | <Document Name>`

### 2. Querying (Answering User Questions)

1. Read `index.md` to locate relevant pages.
2. Read the identified pages to gather context.
3. Summarize the answer and explicitly cite the source wiki pages using wikilinks.
4. If the generated answer holds persistent value, offer to save it as a new wiki page.

### 3. Linting

When instructed to lint the wiki, scan for:

- Orphan pages (pages with no incoming links).
- Conflicting information across different pages.
- Important concepts that are frequently mentioned but lack a dedicated page.
- Missing cross-references between obviously related pages.
- Missing or malformed YAML frontmatter.

---

## Raw Sources Directory

| File | Description |
| :--- | :--- |
| `README.md` | Project overview |
| `Document/srs.md` | Complete Software Requirements Specification |
| `Document/objective.md` | Objectives and KPIs |
| `Document/scop.md` | Project scope and work packages |
| `Document/C1-System-Context-Diagram.md` | C1 Context Diagram |
| `Document/C2-Container-Diagram.md` | C2 Container Diagram |
| `Document/Use-Case-Diagram.md` | Use Case Diagram and FR list |
| `Document/flowchart.md` | User Flow and System Flowchart |
| `design/architecture.md` | Overall system architecture |
| `design/design.md` | Mobile UI/UX design specs |
| `design/mobile.md` | Detailed Mobile App design |
| `design/server.md` | Backend and Server Architecture |
| `design/model.md` | AI Model design |
| `design/training.md` | Model Training pipeline design |

---

## LLM Writing Guidelines

- **Primary Language:** Write all page content primarily in **Thai**. Maintain technical terms (frameworks, protocols, libraries) in English according to industry standards.
- **Synthesis over Copying:** Do NOT copy-paste raw source documents verbatim. Synthesize, summarize, and restructure the information to fit the wiki format.
- **Conflict Resolution:** If conflicting information is found, document it using a `> [!WARNING]` callout block.
- **Information Gaps:** Highlight missing information or open questions using a `> [!NOTE]` callout block.
- **Authority:** If information overlaps between two documents, explicitly state which document is being treated as the authoritative source.
