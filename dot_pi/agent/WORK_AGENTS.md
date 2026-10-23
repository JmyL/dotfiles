# Work (Vay) agent instructions

Company-specific guidance lives here, referenced from `~/.pi/agent/AGENTS.md`. Read this file when a task touches Vay/Vayinfra entities (repos, testbeds, vehicles, telestations, Jira/Confluence/Slack/Grafana/Snowflake). Keep company-specific rules here, not in the global AGENTS.md.

# Testbed name resolution

When Sungsik mentions a bare name like "loki", "apollo", "zeus", treat it as a **testbed short name** and expand it to the full entity name by context:

- **Telestation (ts):** `ts-<country>-<city>-<name>`. Default `ts-de-ber-<name>` (loki → `ts-de-ber-loki`). Las Vegas sites use `ts-us-las-<name>` (e.g. `ts-us-las-00013`).
- **Vehicle (ve):** `ve-<country>-<name>`. Default `ve-de-<name>` (loki → `ve-de-loki`). US fleet vehicles are numeric (`ve-us-00230`).

Rules:

- If the task already makes the domain clear (e.g. "testbed에서 로그 봐", "그 차량 데이터"), pick the matching prefix: telestation → `ts-de-ber-`, vehicle → `ve-de-`.
- If the bare name alone is ambiguous between ts and ve, ask once or resolve both; do not silently pick one.
- Names with numeric ids (e.g. "00013") keep the number as the name segment.
- When a resolved name must be authoritative (fleet entity lookup, session data, vayplay link), verify it against the source of truth (e.g. CCMS via the `vay-ccms-configs` skill) instead of trusting the pattern blindly.
