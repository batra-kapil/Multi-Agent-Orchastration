# Multi-Agent Orchestration — Employee Onboarding with Agentforce

> Built by [Kapil Batra](https://www.linkedin.com/in/hellokapil) | [SF Bolt YouTube Channel](https://www.youtube.com/@salesforcebolt)

This repository contains the complete source code for the **Employee Onboarding Multi-Agent Orchestration solution** built using **Agentforce Summer '26 Beta** — demonstrated in the SF Bolt video on multi-agent orchestration.

---

## What Is This?

This project demonstrates how to build a multi-agent orchestration solution in Agentforce using the brand new **Connect Agent as Subagent (Beta)** feature released in Summer '26.

Instead of one agent trying to handle everything, this solution uses four independent agents — one orchestrator and three specialists — that collaborate to complete a full employee onboarding workflow from a single conversation.

### What the Solution Does

An HR manager starts a conversation with the Onboarding Orchestrator and provides a new hire's name, department, and office location. The Orchestrator delegates to three specialist agents in sequence and returns a complete onboarding summary.

| Agent | Responsibility |
|---|---|
| **Onboarding Orchestrator** | Primary agent — single point of contact, delegates to all three specialists |
| **IT Provisioning Agent** | Provisions system access based on department, creates IT support request |
| **HR Setup Agent** | Creates HR profile, assigns HR system, marks welcome email and checklist sent |
| **Facilities Agent** | Assigns desk, floor, and parking slot based on office location |

### Routing Logic

**IT System provisioning by department:**

| Department | Systems Provisioned |
|---|---|
| Engineering | GitHub, Jira, Confluence, Slack |
| Finance | SAP, Salesforce, Excel Online |
| HR | Workday, Salesforce, Teams |
| Other | Salesforce, Teams, Email |

**HR System by department:**

| Department | HR System |
|---|---|
| Finance | SAP SuccessFactors |
| All others | Workday |

**Facilities by office location:**

| Location | Desk | Floor | Parking |
|---|---|---|---|
| Hyderabad | HYD-A-042 | Floor 3, Block A | HYD-P-12 |
| Mumbai | MUM-B-018 | Floor 5, Block B | MUM-P-07 |
| Delhi | DEL-C-031 | Floor 2, Block C | DEL-P-22 |

---

## Why Multi-Agent Over a Single Agent?

The most important architectural question — and the one we answer explicitly in the video.

**Single agent with multiple subagents (topics):**
- All subagents share the same context, memory, and configuration
- The IT Provisioning logic is locked inside this one agent forever
- Sequential only — no true parallel coordination
- Works fine for simple, contained use cases

**Separate agents with an orchestrator (this project):**
- Each specialist agent is fully independent
- The IT Provisioning Agent can be reused by an Offboarding Orchestrator, a Role Change Orchestrator, or any future workflow
- Each agent has its own guardrails, persona, and configuration
- This is the enterprise pattern Salesforce recommends for complex, multi-domain workflows

**The reusability argument is the decisive one.** When your IT provisioning rules change, you update one agent. Nothing else changes.

---

## Repository Structure

```
Multi-Agent-Orchastration/
├── force-app/
│   └── main/
│       └── default/
│           ├── flows/
│           │   ├── Create_Onboarding_Request.flow-meta.xml
│           │   ├── Provision_IT_Access.flow-meta.xml
│           │   ├── Setup_HR_Profile.flow-meta.xml
│           │   ├── Assign_Facilities.flow-meta.xml
│           │   └── Complete_Onboarding_Summary.flow-meta.xml
│           └── objects/
│               ├── Onboarding_Request__c/
│               │   └── Onboarding_Request__c.object-meta.xml
│               ├── IT_Support_Request__c/
│               │   └── IT_Support_Request__c.object-meta.xml
│               ├── HR_Setup_Request__c/
│               │   └── HR_Setup_Request__c.object-meta.xml
│               ├── Facilities_Request__c/
│               │   └── Facilities_Request__c.object-meta.xml
│               └── Contact/
│                   └── fields/
│                       ├── EmployeeNumber__c.field-meta.xml
│                       ├── Has_MFA__c.field-meta.xml
│                       ├── Under_Warranty__c.field-meta.xml
│                       └── Password_Reset_Required__c.field-meta.xml
└── README.md
```

> Note: Agent metadata (GenAiPlannerBundle) is retrieved separately via `sf project retrieve start`. See deployment steps below.

---

## Prerequisites

Before deploying this project you need:

- Salesforce Developer Edition org with **Einstein and Agentforce enabled**
- **Summer '26 pre-release org** — Connect Agent as Subagent is a Summer '26 Beta feature
- **Salesforce CLI v2** installed — verify with `sf -v`
- **VS Code** with the Salesforce Extension Pack installed
- **Agentforce DX VS Code Extension** installed
- An authorized SFDX project connected to your org
- API version **67.0** or higher

---

## Custom Objects

### Onboarding_Request__c — Master record (ONB-{0000})

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| Employee Name | Employee_Name__c | Text (100) | Required |
| Department | Department__c | Picklist | Engineering, Finance, HR, Sales |
| Office Location | Office_Location__c | Picklist | Hyderabad, Mumbai, Delhi |
| Status | Status__c | Picklist | In Progress, Completed, Failed |
| IT Status | IT_Status__c | Text (255) | Written by Orchestrator after IT agent responds |
| HR Status | HR_Status__c | Text (255) | Written by Orchestrator after HR agent responds |
| Facilities Status | Facilities_Status__c | Text (255) | Written by Orchestrator after Facilities agent responds |
| Summary | Summary__c | Long Text Area | Final onboarding summary |

---

### IT_Support_Request__c — IT provisioning record (IT-{0000})

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| Employee Name | Employee_Name__c | Text (100) | |
| Department | Department__c | Text (100) | |
| Issue Type | Issue_Type__c | Picklist | password_reset, software_access, hardware |
| Notes | Notes__c | Long Text Area | Contains the list of systems provisioned |
| Status | Status__c | Picklist | Open, Pending Approval, Escalated, Resolved |
| Requires Manager Approval | Requires_Manager_Approval__c | Checkbox | Default: false |
| Chargeable | Chargeable__c | Checkbox | Default: false |

---

### HR_Setup_Request__c — HR profile record (HR-{0000})

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| Employee Name | Employee_Name__c | Text (100) | |
| Department | Department__c | Text (100) | |
| Onboarding Request | Onboarding_Request__c | Lookup | Links to master record |
| HR System | HR_System__c | Text (100) | Workday or SAP SuccessFactors |
| Welcome Email Sent | Welcome_Email_Sent__c | Checkbox | Default: false |
| Checklist Assigned | Checklist_Assigned__c | Checkbox | Default: false |
| Status | Status__c | Picklist | Pending, Completed |

---

### Facilities_Request__c — Facilities assignment record (FAC-{0000})

| Field Label | API Name | Type | Notes |
|---|---|---|---|
| Employee Name | Employee_Name__c | Text (100) | |
| Office Location | Office_Location__c | Picklist | Hyderabad, Mumbai, Delhi |
| Onboarding Request | Onboarding_Request__c | Lookup | Links to master record |
| Desk Number | Desk_Number__c | Text (50) | |
| Floor | Floor__c | Text (50) | |
| Parking Slot | Parking_Slot__c | Text (50) | |
| Status | Status__c | Picklist | Pending, Assigned |

---

## Flows

### 1. Create_Onboarding_Request
**Purpose:** Creates the master Onboarding_Request__c record and returns its ID for use by all downstream agents.

| Variable | Direction | Type | Description |
|---|---|---|---|
| employee_name | Input | Text | Full name of the new employee |
| department | Input | Text | Employee department |
| office_location | Input | Text | Employee office location |
| onboarding_request_id | Output | Text | Salesforce record ID of the created master record |

**Logic:** Creates Onboarding_Request__c with Status = In Progress. Uses `storeOutputAutomatically` to capture the record ID.

---

### 2. Provision_IT_Access
**Purpose:** Assigns systems based on department, creates an IT_Support_Request__c record, and returns the systems list and record ID.

| Variable | Direction | Type | Description |
|---|---|---|---|
| employee_name | Input | Text | Full name of the new employee |
| department | Input | Text | Employee department for routing |
| onboarding_request_id | Input | Text | Master record ID |
| systems_provisioned | Output | Text | Comma-separated list of provisioned systems |
| it_request_id | Output | Text | Salesforce record ID of the created IT request |

**Logic:** Decision element branches on department value → assigns systems_text → creates IT_Support_Request__c with Issue_Type = software_access, Notes = systems_text.

---

### 3. Setup_HR_Profile
**Purpose:** Assigns HR system based on department, creates HR_Setup_Request__c, marks welcome email and checklist as complete.

| Variable | Direction | Type | Description |
|---|---|---|---|
| employee_name | Input | Text | Full name of the new employee |
| department | Input | Text | Employee department |
| onboarding_request_id | Input | Text | Master record ID |
| hr_request_id | Output | Text | Salesforce record ID of the created HR record |
| hr_system | Output | Text | HR system assigned |

**Logic:** Decision checks if department = Finance → SAP SuccessFactors, else → Workday. Creates HR_Setup_Request__c with Welcome_Email_Sent__c = true, Checklist_Assigned__c = true, Status = Completed.

---

### 4. Assign_Facilities
**Purpose:** Assigns desk, floor, and parking slot based on office location and creates Facilities_Request__c.

| Variable | Direction | Type | Description |
|---|---|---|---|
| employee_name | Input | Text | Full name of the new employee |
| office_location | Input | Text | Employee office location |
| onboarding_request_id | Input | Text | Master record ID |
| desk_number | Output | Text | Assigned desk number |
| floor | Output | Text | Assigned floor |
| parking_slot | Output | Text | Assigned parking slot |
| facilities_request_id | Output | Text | Salesforce record ID of the created facilities record |

**Logic:** Decision branches on office_location → Hyderabad, Mumbai, Delhi, or default → assigns desk/floor/parking values → creates Facilities_Request__c with Status = Assigned.

---

### 5. Complete_Onboarding_Summary
**Purpose:** Updates the master Onboarding_Request__c record with all three specialist results and marks it as Completed.

| Variable | Direction | Type | Description |
|---|---|---|---|
| onboarding_request_id | Input | Text | Master record ID |
| it_summary | Input | Text | IT provisioning result from IT agent |
| hr_summary | Input | Text | HR setup result from HR agent |
| facilities_summary | Input | Text | Facilities assignment result from Facilities agent |
| completion_confirmed | Output | Boolean | True if update succeeded |

**Logic:** Updates Onboarding_Request__c — sets Status = Completed, IT_Status__c, HR_Status__c, Facilities_Status__c from inputs. Sets completion_confirmed = true on success.

---

## Agent Configuration

### Build Order — This Matters

Specialist agents must be built and **activated** before the Orchestrator. The Orchestrator needs existing active agents to connect to.

```
1. IT Provisioning Agent     → activate
2. HR Setup Agent            → activate
3. Facilities Agent          → activate
4. Onboarding Orchestrator   → connect all three → activate
```

---

### IT Provisioning Agent

- **Agent Type:** Employee Agent
- **API Name:** IT_Provisioning_Agent
- **Subagent:** IT_Provisioning_Handler
- **Action:** Provision_IT_Access flow
- **Instructions:** Provision system access for new employees. Always use the action. Never guess system assignments.

---

### HR Setup Agent

- **Agent Type:** Employee Agent
- **API Name:** HR_Setup_Agent
- **Subagent:** HR_Setup_Handler
- **Action:** Setup_HR_Profile flow
- **Instructions:** Set up HR profile for new employees. Always use the action. Confirm HR system, welcome email, and checklist on completion.

---

### Facilities Agent

- **Agent Type:** Employee Agent
- **API Name:** Facilities_Agent
- **Subagent:** Facilities_Handler
- **Action:** Assign_Facilities flow
- **Instructions:** Assign desk and parking for new employees. Always use the action. Confirm desk number, floor, and parking slot on completion.

---

### Onboarding Orchestrator

- **Agent Type:** Employee Agent
- **API Name:** Onboarding_Orchestrator
- **Subagent:** Onboarding_Handler
- **Flow Actions:** Create_Onboarding_Request, Complete_Onboarding_Summary
- **Connected Subagents (Beta):** IT_Provisioning_Agent, HR_Setup_Agent, Facilities_Agent

**Orchestrator instructions:**
```
Follow this sequence for every onboarding request:
1. Call Create Onboarding Request — store the returned onboarding request ID
2. Call IT Provisioning Agent with employee name, department, and onboarding request ID
3. Call HR Setup Agent with employee name, department, and onboarding request ID
4. Call Facilities Agent with employee name, office location, and onboarding request ID
5. Call Complete Onboarding Summary with the onboarding request ID and results from all three agents
6. Present the full onboarding summary to the HR manager
Never skip any step. Never proceed to the next step until the current one confirms completion.
```

---

### Connect Agent as Subagent — Summer '26 Beta

This is the key step that enables multi-agent orchestration.

1. Open the Onboarding Orchestrator in the **new Agent Builder** (not legacy) in draft state
2. In the Explorer panel click **+**
3. Select **"Connect Agent as Subagent (Beta)"**
4. Add IT Provisioning Agent, HR Setup Agent, Facilities Agent
5. In Canvas view — add all three to **Actions Available for Reasoning**
6. Bind system inputs for each connected agent:

```yaml
ContactId: string = @variables.ContactId
RoutableId: string = @variables.RoutableId
EndUserLanguage: string = @variables.EndUserLanguage
EndUserId: string = @variables.EndUserId
```

7. Commit version → Activate

> The variable bindings are required — the validator will block activation with 24 errors if these are not set. This is a known behavior of the Beta feature.

---

## How to Deploy

### Step 1 — Clone the repository

```bash
git clone https://github.com/batra-kapil/Multi-Agent-Orchastration.git
cd Multi-Agent-Orchastration
```

### Step 2 — Authorize your org

```bash
sf org login web --alias your-org-alias
```

### Step 3 — Deploy objects first

```bash
sf project deploy start \
  --source-dir force-app/main/default/objects \
  --target-org your-org-alias
```

### Step 4 — Deploy Contact custom fields

```bash
sf project deploy start \
  --metadata "CustomField:Contact.EmployeeNumber__c" \
  --metadata "CustomField:Contact.Has_MFA__c" \
  --metadata "CustomField:Contact.Under_Warranty__c" \
  --metadata "CustomField:Contact.Password_Reset_Required__c" \
  --target-org your-org-alias
```

### Step 5 — Deploy flows

```bash
sf project deploy start \
  --source-dir force-app/main/default/flows \
  --target-org your-org-alias
```

> All five flows must deploy and activate successfully before building any agents.

### Step 6 — Build agents in UI

Build all four agents in the new Agent Builder following the configuration above. Deploy order: IT Provisioning Agent → HR Setup Agent → Facilities Agent → Onboarding Orchestrator.

### Step 7 — Retrieve agent metadata (optional)

After building and activating all agents in the UI, retrieve the generated metadata:

```bash
sf project retrieve start \
  --metadata "GenAiPlannerBundle" \
  --target-org your-org-alias
```

---

## Test Conversations

Run these in the Onboarding Orchestrator Preview panel.

**Test 1 — Engineering, Hyderabad (Priya Sharma)**
```
I need to onboard a new employee. Her name is Priya Sharma, 
she is joining the Engineering department and will be based in Hyderabad.
```
Expected: GitHub, Jira, Confluence, Slack provisioned · Workday HR system · HYD-A-042 desk

**Test 2 — Finance, Mumbai (Rahul Mehta)**
```
I need to onboard a new employee. His name is Rahul Mehta, 
he is joining the Finance department and will be based in Mumbai.
```
Expected: SAP, Salesforce, Excel Online provisioned · SAP SuccessFactors HR system · MUM-B-018 desk

**Test 3 — HR, Delhi (Amit Verma)**
```
I need to onboard a new employee. His name is Amit Verma, 
he is joining the HR department and will be based in Delhi.
```
Expected: Workday, Salesforce, Teams provisioned · Workday HR system · DEL-C-031 desk

---

## Verifying Records via SOQL

After each test run, verify all four records were created:

```sql
SELECT Id, Employee_Name__c, Department__c, Office_Location__c, 
       Status__c, IT_Status__c, HR_Status__c, Facilities_Status__c
FROM Onboarding_Request__c
ORDER BY CreatedDate DESC LIMIT 3
```

```sql
SELECT Id, Employee_Name__c, Department__c, Issue_Type__c, Notes__c, Status__c
FROM IT_Support_Request__c
ORDER BY CreatedDate DESC LIMIT 3
```

```sql
SELECT Id, Employee_Name__c, Department__c, HR_System__c, 
       Status__c, Welcome_Email_Sent__c, Checklist_Assigned__c
FROM HR_Setup_Request__c
ORDER BY CreatedDate DESC LIMIT 3
```

```sql
SELECT Id, Employee_Name__c, Office_Location__c, 
       Desk_Number__c, Floor__c, Parking_Slot__c, Status__c
FROM Facilities_Request__c
ORDER BY CreatedDate DESC LIMIT 3
```

---

## Debugging

### Interaction Summary — Agentforce Builder

Open Agentforce Builder → run a test conversation → check the **Interaction Summary** panel on the right. Look for **"Connected Subagent"** entries — these confirm each specialist agent was called. You will see one entry per specialist agent in sequence.

### Trace Tab — Agentforce Builder

Expand the **Trace tab** at the bottom for step-level timing and execution detail.

### Agent Tracer — VS Code

Open the **Agent Tracer tab** in the Agentforce DX VS Code extension for full JSON execution traces including variable state at each step.

---

## Known Issues and Notes

- **Connect Agent as Subagent is Beta** — behavior may change before GA. Test in a pre-release or sandbox org before using in production.
- **Variable binding required** — all four system inputs (ContactId, RoutableId, EndUserId, EndUserLanguage) must be explicitly bound to `@variables.X` in the connected subagent definition in Agent Script. Without this, the validator will block activation.
- **Build order is mandatory** — specialist agents must be active before the Orchestrator is built. The "Connect Agent as Subagent" option only shows agents that already exist and are active.
- **New Agent Builder required** — this feature does not appear in the legacy Agentforce Builder. You must use the new Agent Builder (Summer '26).
- **API version 67.0 required** — flows must be deployed at API v67.0 using `storeOutputAutomatically` for record ID capture.

---

## Resources

- [Agentforce Multi-Agent Orchestration — Summer '26 Release Notes](https://help.salesforce.com/s/articleView?id=release-notes.salesforce_release_notes.htm&release=262&type=5)
- [Orchestrate Other Agents (Beta) — Official Documentation](https://help.salesforce.com)
- [Agentforce DX Extension for VS Code](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode-agentforce)
- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)

---

## About SF Bolt

SF Bolt is a YouTube channel and LinkedIn brand focused on Salesforce and AI content — built by Kapil Batra, Salesforce MVP and Certified Application Architect.

- YouTube: [SF Bolt](https://www.youtube.com/watch?v=lKZZ1zUgadw)
- LinkedIn: [Kapil Batra](https://www.linkedin.com/in/hellokapil)
- GitHub: [batra-kapil](https://github.com/batra-kapil)
- Website: [salesforcebolt.com](https://salesforcebolt.com)

---

*If this helped you, star the repo and subscribe to Salesforce Bolt for more Agentforce content every week.*
