---
name: interactive-learning
description: Create interactive HTML learning documents on any topic. Generates a self-contained workshop page with overview, Mermaid diagrams, design scenarios with reveal/deeper-dive sections, discussion prompts, and quizzes.
---

# Interactive Learning Workshop Generator

Create a self-contained interactive HTML document for learning a topic in depth. The output is a single `.html` file the user opens in a browser - no build step, no dependencies beyond a Mermaid CDN import.

## When to use

- User wants to learn a topic (system design, architecture patterns, a technology, a domain concept)
- User asks for an interactive study guide, workshop, or explainer
- User says "teach me about X" or "create a learning doc for X"

## Process

### 1. Understand scope

Ask the user **one question** to calibrate:

> "What's your starting point with [topic]? I'll pitch the content at the right level - from foundational concepts up to staff-engineer interview depth."

If the user provides a codebase or project as context, ground the examples and scenarios in that real system rather than using abstract examples. Real systems make better teaching material.

### 2. Plan the structure

Before writing, decide on:

- **3-5 overview sections** covering the core concepts (architecture, data flow, key patterns, trade-offs)
- **3-5 design scenarios** that challenge the reader to think about changes, failures, or scale
- **4-6 quiz questions** testing understanding of the concepts and trade-offs
- **Diagrams** - identify which concepts benefit from visual representation (architecture overviews, data flows, sequences, comparisons)

### 3. Generate the HTML document

Use the template structure below. The output is a **single self-contained HTML file** with inline CSS, inline JS, and Mermaid loaded from CDN.

Save to `~/Projects/learning/`. Use a descriptive filename: `{topic}-workshop.html`.

## Document structure

The HTML document follows this structure:

```
1. Page header (title + subtitle, full width)
2. Two-column layout: sticky sidebar TOC + main content
3. Overview sections (concepts, with diagrams)
4. Key decisions / principles (2-column grid of trade-off cards)
5. Design scenarios (side-by-side prompt + notepad, reveal, deeper-dive, discuss-with-Claude)
6. Quick-fire quiz (2-column grid of quiz cards)
7. Score bar (fixed footer tracking progress + export/import)
```

### Overview sections

Introduce core concepts with clear prose. Use **Mermaid diagrams** for:
- Architecture overviews (`graph TD`)
- Data/request flows (`sequenceDiagram`)
- Component relationships (`graph LR` with subgraphs)
- Process pipelines (`sequenceDiagram` with `rect` blocks for phases)

**Theme-safe diagram styling:** When using `style` directives in Mermaid source, always use `color:#edf0f7` for node text. The template's JS swaps this exact value to `color:#111827` in light mode. Any other text colour (e.g. `color:#fff`, `color:white`) will not be swapped and will be unreadable in light mode. Fill and stroke colours with low alpha (e.g. `fill:#60a5fa20`, `stroke:#60a5fa`) work on both themes without modification.

For comparison data (weights, feature matrices, scoring), use **styled HTML cards** (side-by-side grid) rather than Mermaid - tabular data reads better as cards. Use CSS variables for colours in inline styles (`var(--accent)`, `var(--green)`, `var(--yellow)`, `var(--red)`) so cards adapt to light/dark theme.

### Design scenarios

Each scenario follows this pattern:

```html
<div class="scenario" id="scenario-N">
  <!-- Numbered header -->
  <!-- Topic tags (coloured pills) -->
  <!-- Scenario description: what changed, what's the challenge? -->
  <!-- Side-by-side prompt + notepad: -->
  <div class="scenario-interact">
    <!-- Left: "Think about: ..." (italic hint) -->
    <!-- Right: textarea for jotting thoughts before reveal -->
  </div>
  <!-- Reveal button + hidden discussion content -->
  <!--   Inside reveal: -->
  <!--     Analysis of what breaks / what to consider -->
  <!--     Proposed approach with code/architecture snippets -->
  <!--     "Go deeper" expandable section (advanced tangent) -->
  <!--     "Discuss with Claude" prompt (yellow box with a follow-up question) -->
</div>
```

**Scenario design principles:**
- Ground scenarios in realistic constraints (rate limits, cost, latency requirements, team size)
- Include at least one scenario about **failure/resilience** and one about **scale**
- The "discuss with Claude" prompt should pose a genuinely interesting follow-up that doesn't have one right answer
- Deeper dives should cover a related pattern or principle the reader might not know

### Quiz questions

Multiple choice (A-D), one correct answer per question. The explanation should:
- State why the correct answer is right
- Briefly explain why the most tempting wrong answer is wrong
- Connect back to a concept from the overview sections

### Score tracking

Fixed footer bar showing: quiz score (N / total) and scenarios explored (N / total).

## Template

The complete HTML template with all CSS, JS, and Mermaid config is in `./template.html`. **Read this file and use it as the structural foundation** for every generated document. Adapt the content sections but preserve the CSS variables, component patterns, and JS interactions exactly.

Key template features (read `./template.html` for full implementation details):
- **Dark/light theme** with toggle button in score bar. Defaults to dark, respects `prefers-color-scheme` on first visit, persists choice. Mermaid diagrams automatically re-render with the correct theme.
- **Wide desktop layout** (max-width: 1400px) with two-column grid: sticky sidebar TOC (220px) + main content. Prose capped at `max-width: 70ch`; diagrams, code blocks, and grids use full content width.
- **2-column grids** for key decisions (`.decisions-grid`), quiz questions (`.quiz-grid`), and scenario prompt+notepad (`.scenario-interact`).
- **Mermaid.js v11** via ESM CDN with `useMaxWidth: false` and fontSize 16px so diagrams render at natural size with horizontal scroll.
- **State persistence** via localStorage (debounced 300ms) for notepads, quiz answers, reveals, and deeper dives. Export/Import buttons for portable backup.
- **Interactive components**: reveal toggles, deeper-dive accordions, quiz with answer locking, scroll spy on sidebar TOC, coloured topic tags.

## Quality checklist

Before delivering the document:

- [ ] All Mermaid diagrams render (no syntax errors - test by opening in browser)
- [ ] Every scenario has: description, prompt, notepad, reveal, deeper-dive, and discuss-with-Claude
- [ ] Quiz explanations reference why wrong answers are wrong, not just why the right one is right
- [ ] No placeholder text ("TBD", "add later", etc.)
- [ ] Content is grounded in the specific topic/codebase, not generic
- [ ] "Discuss with Claude" prompts pose genuine dilemmas, not questions with obvious answers
- [ ] Diagrams use appropriate type (flowchart for architecture, sequence for flows, cards for comparisons)
- [ ] Mermaid `style` directives use `color:#edf0f7` for text (see theme-safe diagram styling above)
- [ ] No hardcoded hex colours in inline styles - use CSS variables (`var(--accent)`, `var(--green)`, etc.)
- [ ] Page is readable in both light and dark mode (toggle in score bar)

## Tone

Write as a knowledgeable colleague explaining to a peer, not a textbook. Use "you" directly. Be opinionated about trade-offs - state what you'd recommend and why, then acknowledge the counterargument. Dry wit welcome.
