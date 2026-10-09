# Zoom, depth, refinement and budgets

## Who reads which zoom

- `product`: founders, designers, support, QA: anyone who judges by what they see. It fits flows and pairs with the `run` check.
- `contract`: engineers on either side of a boundary, and API consumers. It pairs with `run` against the API, or with `tests`.
- `code`: the author and the reviewer of a function where a wrong branch costs most: money, permissions, state machines, parsers. It pairs with `trace` and `tests`.

Each pair is one level of a V-model: `product` trees are the acceptance tests, `contract` trees the integration tests, `code` trees the unit tests.

## One behaviour at every zoom

The behaviour: a customer cancels an order.

### product, outline

```text
orders::cancel order [web, ios]
├── given the order has shipped
│  └── it should offer no cancel action
└── when the customer cancels an unshipped order
   └── it should show the order as "Cancelled"
```

### product, full

```text
orders::cancel order [web, ios]
├── given the order has shipped
│  └── it should offer no cancel action
├── when the customer cancels without picking a reason
│  └── it should keep the dialog open and ask for a reason
└── given the order has not shipped
   └── when the customer cancels with a reason
      └── it should show the order as "Cancelled"
         ├── it should show the refund amount and the day it lands
         └── it should send a cancellation email
```

### contract, full

```text
orders::POST /orders/:id/cancel [api]
├── given no session
│  └── it should return 401
├── given the order belongs to another customer
│  └── it should return 404
├── when the body has no reason
│  └── it should return 422 naming `reason`
├── given the order is shipped or delivered
│  └── it should return 409 with code `ORDER_NOT_CANCELLABLE`
├── given the order is already cancelled
│  └── it should return 200 with the order unchanged
└── given the order is pending or paid
   └── it should return 200 with status `cancelled`
      ├── it should publish {OrderCancelled} once
      └── it should enqueue a refund job when the order is paid
```

### code, exhaustive

```text
OrderService::cancel [src/orders/service.ts]
├── when `reason` is blank after trimming
│  └── it should throw `ValidationError` on `reason` before any read
├── when `findById` returns null
│  └── it should throw `OrderNotFound`
├── when the status is `shipped` or `delivered`
│  └── it should throw `OrderNotCancellable` carrying the status
├── when the status is `cancelled`
│  └── it should return the order without a write
├── when the status is `pending`
│  └── it should return the order with status `cancelled`
│     ├── it should not call `refunds.create`
│     ├── it should write `status`, `cancelledAt` and `reason` in one transaction
│     └── it should publish {OrderCancelled} after the commit
└── when the status is `paid`
   ├── given `refunds.create` throws
   │  └── it should rethrow and write nothing
   └── given `refunds.create` resolves
      └── it should return the order with status `cancelled`
         ├── it should call `refunds.create` once with the captured amount
         ├── it should write `status`, `cancelledAt` and `reason` in one transaction
         └── it should publish {OrderCancelled} after the commit
```

The product tree says nothing a customer cannot see. The contract tree names every response a caller must handle. The code tree follows the guards in source order and names each call and write, so a reviewer can hold it beside the function.

The four trees show the zooms side by side; a home keeps each decision in one of them. The contract tree's 422 restates the product rule that a reason is required, so a home that holds both drops it there. Its refund job is a decision no screen shows, so it may stay, as a child that refines the product outcome.

## Refinement

Zoom says whose words a tree uses. Refinement says how fine it goes. They are separate: a product outcome can open into a finer product tree, and a contract outcome into a code tree.

### Levels

- Home: a product, a package or a pillar.
- Area: an epic or a capability; a summary goal.
- Unit at `product` zoom: a user story; one actor, one goal, one sitting.
- Leaf and its path: an acceptance criterion; the path is its Given-When-Then scenario.
- Child: a finer requirement under one outcome: a sub-story at the same zoom, or the contract and code rules behind it; a subfunction.

### Refine, never restate

A child names one outcome of its parent on its `// REFINES:` line. It holds only on the parent's path to that outcome, and adds only the decisions the outcome leaves open. It repeats none of the parent's conditions and not its outcome: restated copies drift apart. It keeps its parent's zoom or zooms in, never out. It lives in the area whose readers own its decisions: a sub-story beside its parent, a contract child in a contract area.

```text
refunds::refund shown on cancel
// REFINES: orders::cancel order > it should show the refund amount and the day it lands
├── given the order was paid with store credit
│  └── it should show the credit back on the account at once
└── given the order was paid by card
   └── it should show the full amount and a date 5 to 10 business days out
```

The parent promises a refund amount and a day. The child decides both by payment method, which the parent's reader need not hold. A contract child under the same outcome could decide what makes a refund request safe to retry, which no screen shows.

### When to refine

Refine an outcome only when it hides a decision someone could make differently that the parent's reader does not own. Otherwise it stays one leaf, and code and tests own its detail. The rank below says how far each area refines.

### Split a story

Split along the lines agile teams use, SPIDR:

- Paths: each alternative path is a sibling branch; a long flow splits into units by step.
- Interfaces: a behaviour that differs by place gets its own tree with fewer places.
- Data: merge conditions that share an outcome, and point one leaf at a table in the authority.
- Rules: a rule that varies by case opens into a child under the outcome it changes.
- Spikes: an unknown stays an `// OPEN:` line until someone answers it.

## Budgets

Size the home to the attention of the people who align it, not to the size of the code. A leaf costs a human about half a minute to read and decide, and every check pays for it again. A home nobody finishes aligning states nobody's intent. Each level has its own readers: the product owner aligns a parent, engineers align its contract and code children. In a home split by audience, a child lives in its readers' home, under that home's budget.

A leaf earns its place only when someone could reasonably want a different outcome. "It should list the notes" fails that test unless order, filter or emptiness matters to someone. Behaviour that fails the test is implementation; code and tests own it.

Default boundaries. The index may override the three leaf counts on its `Budget:` line, and `scripts/trees audit` warns past them.

- Leaf: one outcome someone could decide differently, with at most three effects.
- Tree: at most three levels of branches under the root. A deeper rule opens into a child.
- Unit: 3 to 12 leaves, about 40 lines. One screen, aligned in about five minutes. At `code` zoom the 12 binds each function tree.
- Area: at most 12 units and 80 leaves. One sitting of about 40 minutes.
- Home: at most 15 areas and 1,000 leaves. A full alignment in one working day. In a split repo, each home has its own budget.
- `code` zoom: at most a tenth of the home's leaves.

Spend depth by risk. Rank every area when you map it. A unit may override its area's rank on the card, and a child takes its parent unit's rank unless its own card says otherwise:

- Critical: money, data loss, security, legal promises, anything irreversible. `full` depth, and children down to `code` zoom for the few outcomes at its core.
- Core: the daily job of the main actors. `full` depth, and a child where a rule changes by case.
- Peripheral: browsing, filters, views, settings. `outline` depth, and no children.

Stay inside a budget without dropping behaviour:

1. Merge conditions that share an outcome: `given the note is complete or cancelled`.
2. State a cross-cutting rule once. Sign-in, role gates, offline queueing and shared validation get their own unit; other trees leave them out.
3. Leave tables in the authority. One leaf points at a field-limit or permission table, instead of one leaf per row.
4. Give places one tree unless their behaviour differs.
5. Move a heavy outcome's detail into a child, in the area of the people who own it.

Over budget, in this order:

1. Cut the leaves that fail the test above.
2. Split a unit by flow step, and an area by sub-flow. Move an outcome's detail into a child.
3. Move peripheral areas to `outline`.
4. Split the home by product or package.

The budgets bound the first alignment. After it, `align` shows only the branches that changed, so a large aligned home stays cheap to keep aligned.

## Pillars

`map` probes the home before any area. Most software stands on the same pillars, and a pillar with no area is where missing areas hide:

- Identity and access: sign-up, sign-in, roles, sessions, recovery.
- The core domain: the daily work of the main actors.
- Data lifecycle: create, change, archive, delete, export, retention.
- Money: prices, payments, refunds, invoices, credits.
- Communication: emails, notifications and messages, and what triggers each.
- Integrations: outside services, and what happens when one fails.
- Administration: settings, configuration, support tools, feature flags.
- Audit and compliance: history, consent, legal promises.

A pillar the product lacks is a decision in the index, not a missing area.

## Non-functional requirements

Trees state what the software does. A quality becomes a leaf only when a person or a caller can observe it and someone could want it different: a response time, a size limit, an offline promise. Put it at the zoom that observes it. The rest, such as uptime, scale and code quality, stays in its own documents. Name it on an `// OUT OF SCOPE:` line or in the index decisions, so the gap reads as decided.

## What to probe

Every zoom starts from five questions: what must exist before, what input changes the outcome, what the unit produces, what can fail, and where the edges are. Then probe the categories of the zoom. A category with no branch is where missing branches hide.

### product

- Actors and roles, and what each may not do.
- Entry points: screens, links, deep links, notifications, a resumed session.
- States that change what a person sees: empty, loading, error, offline, stale.
- Inputs and how each is refused: blank, too long, wrong format, duplicate.
- Outcomes, and where else they show: another screen, a list, an email, a history.
- Interruptions: a double submit, back, reload mid-step, a second tab, a lost connection.
- Surfaces that differ: web against mobile, desk against field app.

### contract

- Authentication and authorization, and ownership of the target record.
- Validation and limits: required fields, formats, sizes, pagination.
- Not found, gone and conflicting state.
- Idempotency: a retry, a duplicate delivery, a replayed event.
- Side effects and their order: records, events, jobs, emails. Which run on failure?
- Partial failure of a downstream service, and what stays written.
- Rate limits, timeouts and compatibility with older callers.

### code

- Each guard and early return, in source order.
- Each arm of each conditional, including the implicit else.
- Each throw, and each catch with what it swallows or rethrows.
- Each loop at zero, one and many items.
- Null, empty and boundary values for every parameter.
- Calls to collaborators: which ones, how many times, with what arguments, in what order.
- State writes, and when they commit or roll back.
- The shape of the return value on every path.
- Shared state: concurrent calls and reentry.
