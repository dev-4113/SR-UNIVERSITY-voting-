# SR University Digital Campus Voting System

**Local review workflow only.** This version removes the preview-only auto-profile and email-login screen. A reviewer can enter fictional student details, proceed to candidate selection, confirm a test ballot, and see the test ballot stored in local MySQL.

**Important:** This is not an official election system. Do not enter real student information or use it to conduct a university election. The review schema links each test ballot to its test student and is not a secret-ballot design. Official voting remains disabled. Obtain written university approval and have university IT/security teams design and audit the production identity, eligibility, secrecy, duplicate-vote prevention, and election processes before any live use.

## Requirements

- Node.js 20 or newer
- MySQL 8.x
- VS Code (optional)

## 1. Create the MySQL tables

In MySQL Workbench or a VS Code SQL extension, connect to your local MySQL server and execute these scripts in order:

1. `sql/002_mysql_demo_auth.sql` (creates the local database)
2. `sql/003_review_workflow.sql` (creates the review student and review ballot tables)

The current review workflow does not require email OTP.

## 2. Configure the project

Open the inner `sr-university-voting-system` folder in VS Code (the folder containing `package.json`). In CMD or PowerShell, run:

```bash
npm.cmd install
```

Create `.env` from `.env.example`. On PowerShell:

```powershell
Copy-Item .env.example .env
```

On CMD:

```cmd
copy .env.example .env
```

Edit `.env` and set `DB_PASSWORD` to your local MySQL root password. Keep `REVIEW_MODE=true` only for this local review. Do not enable it in production.

## 3. Start the website

```bash
npm.cmd run check
npm.cmd run dev
```

Open `http://localhost:3000`. Do not open `public/index.html` directly; the backend API is required.

If PowerShell blocks `npm.ps1`, use the Windows command shim:

```powershell
npm.cmd install
npm.cmd run check
npm.cmd run dev
```

## 4. Test the flow

1. Enter fictional test details (for example, name `Review Student`, roll number `TEST-001`, department `CSE`, year `2nd Year`).
2. Click **PROCEED TO VOTE**.
3. Select Candidate A, B, or C.
4. Review the confirmation dialog and click **CONFIRM VOTE**.
5. The backend stores one test ballot for that test roll number in MySQL. A second ballot for the same student is rejected.

Use a different fictional roll number for each review test. These records are test data only.

## 5. Verify backend and MySQL

Open `http://localhost:3000/api/health`. It should report `database: connected` and `localReviewMode: true`.

To inspect review data in MySQL:

```sql
USE sr_university_voting_demo;
SELECT * FROM review_students ORDER BY id DESC;
SELECT candidate_name, COUNT(*) AS test_votes
FROM review_ballots GROUP BY candidate_name;
```

## API endpoints

- `GET /api/health` — server and MySQL health
- `POST /api/review/register` — save fictional review student details and start a session
- `POST /api/review/vote` — record one review ballot for the session
- `GET /api/review/results` — read aggregate review counts

## Security and production limitations

- The review flow does not authenticate university identity or check an official student roster.
- Anyone who can access this local review site can submit fictional details.
- The review ballot is linked to the review student record and is not secret.
- The app uses the Express in-memory session store, suitable only for local development.
- The database and endpoints are disabled in production because `REVIEW_MODE` is accepted only when `NODE_ENV` is not `production`.
- Do not deploy this version for a real election. A production election requires written university approval, an approved identity provider and authoritative eligibility roster, independent security review, secret-ballot architecture, atomic one-person-one-vote enforcement, role-based administration, audit controls, HTTPS, persistent session storage, backups, and operational monitoring.
