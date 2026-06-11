---
name: council
description: "Spin up a council of parallel agents with problem-specific perspectives to debate a question, decision, idea, or piece of work. Use when the user wants multiple viewpoints, wants to stress-test an idea, wants to reduce bias, or invokes /council. Works for code, architecture, vault notes, life decisions, brainstorming, or any topic that benefits from diverse angles."
---

# The Council

A general-purpose debiasing tool. Given any problem, it assembles a council of parallel
agents — each with a distinct, problem-relevant perspective — and runs a blind opening
round followed by a deliberation round, skipping deliberation on early convergence and
continuing past it only when the user asks.

The whole point: **you (Claude) have one voice and one set of biases. The council forces
genuinely different lenses onto the same problem so the user gets a fuller picture, not
just your default take.**

## When to Use

- Architecture or design decisions
- Naming, API shape, or UX choices
- Evaluating an idea, plan, or strategy
- Stress-testing a vault note for gaps or bias
- Any "should I X or Y?" question
- Brainstorming where blind spots matter
- Code review from multiple angles
- Life decisions, career choices, trade-offs

## Invocation

The user types `/council` followed by their question or topic. Examples:

```
/council Should I split this monolith into microservices?
/council Review my note on DNS poisoning for blind spots
/council Is this job offer worth taking over my current role?
/council What's the best way to structure auth in this app?
```

If the user gives no topic, ask: "What should the council debate?"

## Process

### Phase 0: Problem Analysis (YOU do this, not the agents)

Before spawning any agents, analyze the problem yourself:

1. **Identify the domain(s):** What fields does this touch? (security, UX, economics, ethics, ops, etc.)
2. **Identify the tension:** What makes this a hard decision? What are the competing forces?
3. **Pick perspectives:** Choose 3-6 perspectives that:
   - Each covers a **distinct dimension** of the problem (not two that would say the same thing)
   - Together they **surround** the problem from all relevant angles
   - At least one is a **contrarian or devil's advocate** that challenges the obvious answer.
     When the question reveals a leaning ("should I rewrite this in Rust?" usually means
     the user already wants to), this seat targets the user's preferred option by name,
     not just "the obvious answer" in the abstract. Point the contrarian at the actual leaning.
   - At least one represents the **end user / person affected** by the decision

   Do NOT pick random archetypes. Do NOT use generic labels like "The Minimalist" or "The
   Philosopher" unless that perspective genuinely matters for THIS problem. Every perspective
   must earn its seat.

   **Choosing the count:** Default to 3 for focused questions, 6 for complex multi-dimensional
   problems. Never go below 3 (too few to triangulate) or above 6 (diminishing returns, noise).

   **Name each perspective** with a vivid, specific title that makes their angle instantly clear.
   "The Sleep-Deprived Oncall Engineer" is better than "Operations Perspective."

4. **Assemble the briefing pack.** Gather the restated question, any artifact under
   discussion (a vault note, a diff, code, a prior conversation excerpt), and constraints
   surfaced in conversation. Small artifacts (a note, a short diff) are inlined verbatim.
   Large ones (a whole codebase, many files) become an explicit file list every member is
   instructed to read in full. If there is no artifact, the pack is just the question plus
   any conversation constraints. The same pack is injected into every agent in every round,
   Phase 2 and Phase 4 agents are fresh spawns and must receive it again.

### Phase 0.5: Briefing (STOP and wait for approval)

Before spawning any agents, present the council setup to the user in this format:

```
## Council Briefing

**Decision:** (the core question the council will debate, restated clearly and concisely)

**The tension:** (one sentence on what makes this hard, the competing forces)

**Briefing pack:** (one manifest line, e.g. `question + Inbox/DNS.md (inlined)`, or
`question + 4 files (listed for each member to read) + constraint: small team, no Rust experience`,
or `question only`. Manifest, not full content. This makes the user's "Add context"
affordance below actionable: they can see what's in the pack and add to it.)

**Proposed council (N members):**

| # | Perspective | Brings to the table |
|---|-------------|---------------------|
| 1 | {Name} | {one line: what unique angle they argue from, what they'll challenge} |
| 2 | {Name} | {one line} |
| ...| ... | ... |

Ready to run? You can:
- Swap a member ("replace 2 with a security perspective")
- Reframe the question ("actually the real question is...")
- Add context ("keep in mind that we also need...")
- Approve ("go", "run it", "looks good")
```

**Do NOT spawn any agents until the user approves.** This follows the standard
approval protocol: Claude proposes, Sauce decides, then Claude executes.

If the user tweaks the briefing (swaps a member, reframes, adds context), update the
briefing with the changes and wait again. Only proceed to Phase 1 after explicit approval.

### Phase 1: Opening Statements (Parallel)

Spawn one agent per perspective using the Agent tool. **All agents run in parallel.**

Each agent's prompt must include:
- The full problem/question as stated by the user
- **The same briefing pack assembled in Phase 0** (artifact inlined, or file list to read,
  or constraints from the conversation). Identical for every agent. Omit the Context block
  entirely only when the pack is question-only.
- Their assigned perspective and what dimension they own
- Instruction to argue FROM that perspective with conviction (not hedge or try to be balanced)
- Instruction to be specific and concrete (no vague platitudes)
- Instruction to end with: "What would change my mind: ..." (one sentence stating the
  condition or evidence that would make them revise their position)
- A 150-word limit for decision questions; up to 300 words when the council is reviewing
  an artifact (note, code, diff), since specific critique needs room to quote

Collect all opening statements.

**Convergence check.** Before spawning Phase 2, scan the opening statements. If perspectives
substantially agree, no genuine disagreement to deliberate, no targeted opponent to respond
to, **skip Phase 2 and go straight to synthesis**. The verdict must flag this and say which
it indicates:
- The answer is clear (problem was less contested than expected), or
- The seats were too alike (name the seat that, in retrospect, might have dissented and was missing).

Running Phase 2 on unanimous Phase 1 statements is agreement theater at multi-agent cost.

### Phase 2: Deliberation (Parallel)

Spawn a second round of agents in parallel. Each agent now receives:

- The original problem
- **The same briefing pack from Phase 0**, re-injected verbatim. Phase 2 agents are fresh
  spawns; they do not inherit Phase 1's context.
- **Their own Phase 1 statement, labeled `YOUR POSITION:`** (separate block, first)
- **All other agents' Phase 1 statements, each labeled by name**
- Their same perspective
- Instruction to do TWO things in order:
  1. **Revise their position with explicit deltas:** "I concede X. I still hold Y. I newly
     argue Z." They must commit to what changed and what didn't after hearing the others.
     If nothing changed, they must say why the other arguments failed to move them.
  2. **Respond to the position that most threatens theirs.** The agent picks their own
     strongest opponent and engages deeply with that one challenge, not a shallow tour
     of everyone's flaws.
- An up-to-500-word limit (substance over length, don't pad to fill it)

### Phase 3: Synthesis (YOU do this, not the agents)

After collecting deliberations, YOU synthesize the debate into a structured verdict:

```
## Council Verdict

**The question:** (restate concisely)

**Perspectives heard:**
- [Name]: one-line summary of their core position

**Falsifiability audit:**
- [Name] said they'd change their mind if {condition}. Outcome: **met** / **not met** / **unresolved** (and why).
(Do this for every agent. Forces you to engage with actual positions, not just summarize.)

**Verify before committing:**
- (One line per **unresolved** audit condition, restated as a concrete check the user can
  run: "Benchmark to confirm I/O is not the bottleneck," "Check whether the team has
  shipped Rust before," etc. Omit this section entirely if no condition came back unresolved.)

**Points of agreement:**
- (what most or all perspectives converged on)

**Key tensions:**
- (genuine disagreements that weren't resolved, with both sides stated fairly)

**Minority report:**
- (If a single member dissented from an otherwise-consensus, state their FULL case here,
  not a one-line summary. The lone dissenter is often where the real value of the run is.
  Omit this section entirely if there is no lone dissent.)

**Blind spots surfaced:**
- (things that only came up because a specific perspective was in the room)

**Recommendation:**
(Your synthesis, not a vote count, but a reasoned take that weighs the strongest arguments.
Be honest about your confidence level. If the council genuinely split with strong arguments
on both sides, say so, don't force a false consensus.

**State the recommendation conditionally when unresolved audit conditions exist:** "Do X,
unless {top unresolved condition} turns out true, in which case {fallback}." Don't hide
the unknowns inside a confident verdict, surface them in the recommendation itself.

**If Phase 2 was skipped due to convergence, say so here**, and name which of the two
diagnoses applies: the answer was clear, or the seats were too alike, and which seat
should have dissented but wasn't in the room.)
```

### Phase 4: Optional Continuation

If the user says "keep going", "dig deeper", or "they didn't resolve X":
- Give each agent the full debate history (Phase 1 statements + Phase 2 deliberations)
- **Re-inject the same `## Context` briefing pack from Phase 0.** Phase 4 agents are fresh
  spawns too, the pack does not carry over.
- Use the same Phase 2 structure: labeled own position (now including their Phase 2 revision),
  delta-format evolution, and self-directed response to their strongest remaining opponent
- Re-synthesize with the new information
- Repeat until the user is satisfied or perspectives have clearly exhausted their arguments

## Rules

1. **No random personas.** Every perspective is chosen because the problem needs it.
2. **No overlap.** Before spawning, verify each perspective covers a unique dimension. If two
   would say basically the same thing, merge them or replace one.
3. **Agents argue with conviction.** The whole point is diverse views. An agent that hedges
   and tries to be balanced defeats the purpose. They can acknowledge good points from others
   in Phase 2, but their job is to represent their angle strongly.
4. **You stay neutral during debate.** In Phases 1-2, you are the facilitator, not a participant.
   You only take a synthesized position in Phase 3.
5. **Keep it tight.** Phase 1 is 150 words for decision questions, up to 300 when reviewing
   an artifact that needs quoting. Phase 2 is up to 500 words (revision + targeted response
   needs room). Neither is a target to fill. Concise, punchy arguments > essays.
6. **Respect the user's time.** For simple questions, 3 agents and 2 rounds is plenty.
   Don't over-engineer a council for "should I use tabs or spaces?"
7. **Always run the briefing.** Phase 0.5 is mandatory. Never skip it, even if the user
   seems eager. The briefing is where bad framing gets caught before tokens are spent.
8. **Every member gets the identical briefing pack.** In every round, all agents receive
   the same question, the same artifact (inlined or as a file list), and the same
   conversation constraints. If members may read files, all members get the same file
   list. Differences between members must come from perspective, never from information
   asymmetry. Phase 2 and Phase 4 agents are fresh spawns and must receive the pack again.

## Agent Prompt Templates

### Phase 1 Template

```
You are "{Perspective Name}" on a council debating the following question:

{question}

## Context
{briefing pack: artifact content inlined, or a file list to read in full, plus any
conversation constraints. Identical to what every other member receives. Omit this
entire block when the pack is question-only.}

Your perspective: {description of what dimension they represent and why it matters here}

Argue FROM your perspective with conviction. Be specific and concrete, not vague.
End with: "What would change my mind: ..." (one sentence, the condition or evidence
that would make you revise your position).

Rules:
- Do not try to be balanced. Your job is to represent your angle strongly.
- Be specific and concrete. Use examples, not platitudes.
- Stay under 150 words for decision questions, or under 300 words if the question is to
  review an artifact (note, code, diff) and you need room to quote specific passages.
- Do not preamble. Start with your strongest point.
```

### Phase 2 Template

```
You are "{Perspective Name}" on a council debating the following question:

{question}

## Context
{same briefing pack as Phase 1, re-injected verbatim. You are a fresh spawn; Phase 1's
context does not carry over. Omit this entire block when the pack is question-only.}

Your perspective: {description of what dimension they represent and why it matters here}

## YOUR POSITION (from Phase 1):
{this agent's own Phase 1 statement}

## Other positions:
**{Agent B Name}:** {Agent B's Phase 1 statement}
**{Agent C Name}:** {Agent C's Phase 1 statement}
...

## Your task (do both, in order):

1. REVISE your position. State explicit deltas:
   - "I concede: ..." (what others convinced you of, or say nothing changed and why)
   - "I still hold: ..." (what you're keeping and why it survived the others' arguments)
   - "I newly argue: ..." (anything the others' statements made you realize)

2. RESPOND to the position that most threatens yours. Name the agent, quote their
   specific claim, and engage deeply. Go after the one argument you find hardest to
   dismiss, not the easiest to rebut.

Rules:
- Argue FROM your perspective with conviction. Do not try to be balanced.
- Be specific and concrete. Use examples, not platitudes.
- Stay under 500 words. Substance over length, don't pad to fill it.
- Do not preamble. Start with your revision.
```

## Example: Perspective Selection

**Question:** "Should I rewrite this Python CLI tool in Rust?"

Bad perspectives (generic, overlapping):
- The Minimalist (vague)
- The Performance Expert (obvious for Rust question)
- The Philosopher (irrelevant)
- The Futurist (hand-wavy)
- The Pragmatist (so generic it could be anyone)

Good perspectives (problem-specific, distinct):
- **The Current Users** — Who uses this tool today? What do they actually need? Would they
  even notice the rewrite?
- **The Maintenance Engineer (2 years from now)** — Who maintains this after the rewrite hype
  fades? Can the team actually write Rust? What's the bus factor?
- **The Performance Auditor** — Where are the actual bottlenecks? Is Python the real problem
  or is it I/O-bound anyway?

Three perspectives, zero overlap, each asking a question the others won't.
