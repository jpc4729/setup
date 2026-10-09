# Tree Syntax Reference

## Connector Rules

- `├──` — non-last child (more siblings follow); the column below it carries `│`
- `└──` — the last child at any level (corner, not tee); the column below it carries spaces, never `│`

```text
root
├── first child          ← has siblings after → ├──
│  ├── grandchild A      ← │ continues because first child has siblings
│  └── grandchild B      ← last grandchild → └──
├── second child         ← still has siblings → ├──
│  └── only grandchild   ← only child → └──
└── last child           ← no more siblings → └──
   └── only grandchild   ← spaces below └──, never │
```

## Keywords

- given: pre-existing state (DB records, auth sessions, feature flags, external service state)
- when: input variation (request body, params, headers, function arguments)
- it should: observable outcome; terminates a branch — never followed by `given`/`when`. An `it should` node
  may have `it should` children: sub-assertions of the same test, not separate branches

`given` and `when` are syntactically interchangeable: `given` for world state, `when` for call input. Project needs no
distinction → use `when` throughout. Consistency beats keyword choice.

## Indentation

A `.tree` file indents 3 spaces from parent connector to child connector, not 2 or 4:

```text
└── parent
   └── child
      └── grandchild
```

## Comments

`//` at line start marks a comment, stripped from generated output:

```text
createUser
├── given unauthenticated
│  └── it should return 401
// OUT OF SCOPE: expired tokens -- covered by auth middleware spec
└── given authenticated
   └── it should create user
```

## Multiple Trees Per File

Separate with two blank lines. Each root uses `Container::function` syntax:

```text
UserService::create
├── given unauthenticated
│  └── it should return 401
└── given authenticated
   └── it should create user


UserService::delete
├── given unauthenticated
│  └── it should return 401
└── given authenticated
   └── it should delete user
```

All trees in one file must map to the same test file — with `Container::function` roots, the same container name.

## Common Mistakes

### 1. Tee for last child

```text
# WRONG
├── given authenticated
├── when body is valid
   └── it should succeed

# CORRECT
├── given authenticated
└── when body is valid
   └── it should succeed
```

### 2. Pipe below corner

```text
# WRONG
└── given authenticated
│  └── it should succeed

# CORRECT
└── given authenticated
   └── it should succeed
```

### 3. Four-space indent

```text
# WRONG
└── parent
    └── child

# CORRECT
└── parent
   └── child
```

### 4. Periods on conditions

```text
# WRONG
├── given user is authenticated.

# CORRECT
├── given user is authenticated
```

No period on a condition — labels, not sentences, like the `it should` leaves.

### 5. Misaligned pipe

```text
# WRONG
├── given authenticated
 │  └── leaf

# CORRECT
├── given authenticated
│  └── leaf
```

## Complete Examples

### REST Endpoint

```text
POST /api/transfers
├── given unauthenticated
│  └── it should return 401
└── given authenticated
   ├── when body is malformed
   │  └── it should return 422 with validation errors
   └── when body is valid
      ├── given sender account not found
      │  └── it should return 404
      └── given sender account exists
         ├── given insufficient balance
         │  └── it should return 409
         └── given sufficient balance
            ├── given recipient not found
            │  └── it should return 404
            └── given recipient exists
               └── it should create transfer
                  ├── it should debit sender
                  ├── it should credit recipient
                  ├── it should persist transaction record
                  ├── it should publish {TransferCompleted} event
                  └── it should return 201
```

### Pure Function

```text
clamp
├── when value is below minimum
│  └── it should return minimum
├── when value is above maximum
│  └── it should return maximum
└── when value is within range
   └── it should return value unchanged
```

### Service with Feature Flags

```text
NotificationService::send
├── given notifications_v2 disabled
│  └── it should send via SMTP
└── given notifications_v2 enabled
   ├── when channel is email
   │  └── it should send via SendGrid
   ├── when channel is sms
   │  ├── given phone number invalid
   │  │  └── it should throw InvalidPhoneError
   │  └── given phone number valid
   │     └── it should send via Twilio
   └── when channel is push
      ├── given no registered devices
      │  └── it should silently skip
      └── given registered devices exist
         └── it should send to all devices
            ├── it should batch per platform
            └── it should log delivery status
```

### Event Handler

```text
onOrderPlaced
├── given order ID is duplicate
│  └── it should skip processing (idempotency)
└── given order ID is new
   ├── given inventory unavailable
   │  └── it should place on backorder
   │     ├── it should persist backorder record
   │     └── it should publish {OrderBackordered} event
   └── given inventory available
      └── it should fulfill order
         ├── it should reserve inventory
         ├── it should charge payment method
         ├── it should create shipment record
         ├── it should publish {OrderFulfilled} event
         └── it should schedule delivery notification
```
