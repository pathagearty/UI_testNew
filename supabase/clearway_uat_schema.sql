-- Clearway synthetic UAT schema for Supabase/PostgreSQL.
-- Contains no credentials and no real patient data.

begin;

-- Idempotent teardown is intentionally limited to Clearway-prefixed objects.
drop view if exists public.clearway_case_payloads;
drop view if exists public.clearway_workspace_payload;

drop table if exists public.clearway_clarifications cascade;
drop table if exists public.clearway_criterion_results cascade;
drop table if exists public.clearway_review_runs cascade;
drop table if exists public.clearway_policy_criteria cascade;
drop table if exists public.clearway_documents cascade;
drop table if exists public.clearway_orders cascade;
drop table if exists public.clearway_prior_auth_cases cascade;
drop table if exists public.clearway_policy_versions cascade;
drop table if exists public.clearway_policies cascade;
drop table if exists public.clearway_coverages cascade;
drop table if exists public.clearway_plans cascade;
drop table if exists public.clearway_payers cascade;
drop table if exists public.clearway_patients cascade;

create table public.clearway_patients (
  patient_id text primary key,
  display_name text not null,
  mrn text not null unique,
  date_of_birth date not null,
  is_synthetic boolean not null default true check (is_synthetic = true),
  created_at timestamptz not null default now()
);

create table public.clearway_payers (
  payer_id text primary key,
  payer_name text not null,
  is_synthetic boolean not null default true check (is_synthetic = true)
);

create table public.clearway_plans (
  plan_id text primary key,
  payer_id text not null references public.clearway_payers(payer_id),
  plan_name text not null,
  plan_type text not null,
  is_synthetic boolean not null default true check (is_synthetic = true)
);

create table public.clearway_coverages (
  coverage_id text primary key,
  patient_id text not null references public.clearway_patients(patient_id),
  plan_id text not null references public.clearway_plans(plan_id),
  member_id text not null,
  effective_start date not null,
  effective_end date not null,
  is_synthetic boolean not null default true check (is_synthetic = true),
  check (effective_end >= effective_start)
);

create table public.clearway_policies (
  policy_id text primary key,
  payer_id text not null references public.clearway_payers(payer_id),
  policy_name text not null,
  procedure_family text not null,
  is_synthetic boolean not null default true check (is_synthetic = true)
);

create table public.clearway_policy_versions (
  policy_version_id text primary key,
  policy_id text not null references public.clearway_policies(policy_id),
  version text not null,
  effective_start date not null,
  effective_end date not null,
  content_hash text not null,
  source_locator text not null,
  is_synthetic boolean not null default true check (is_synthetic = true),
  unique (policy_id, version),
  check (effective_end >= effective_start)
);

create table public.clearway_prior_auth_cases (
  case_id text primary key,
  patient_id text not null references public.clearway_patients(patient_id),
  coverage_id text not null references public.clearway_coverages(coverage_id),
  policy_version_id text not null references public.clearway_policy_versions(policy_version_id),
  case_type text not null,
  scenario text not null check (scenario in ('review_ready', 'needs_documentation', 'conflicting_evidence', 'policy_blocked')),
  request_date date not null,
  case_status text not null default 'open',
  is_synthetic boolean not null default true check (is_synthetic = true),
  created_at timestamptz not null default now()
);

create table public.clearway_orders (
  order_id text primary key,
  case_id text not null references public.clearway_prior_auth_cases(case_id) on delete cascade,
  patient_id text not null references public.clearway_patients(patient_id),
  procedure_name text not null,
  procedure_code text not null,
  code_system text not null,
  ordered_date date not null,
  service_date date,
  ordering_clinician text not null,
  order_status text not null default 'Active',
  is_synthetic boolean not null default true check (is_synthetic = true)
);

create table public.clearway_documents (
  document_id text primary key,
  case_id text not null references public.clearway_prior_auth_cases(case_id) on delete cascade,
  patient_id text not null references public.clearway_patients(patient_id),
  document_type text not null,
  title text not null,
  document_date date,
  display_date text not null,
  present boolean not null,
  source_uri text,
  content_hash text,
  is_synthetic boolean not null default true check (is_synthetic = true)
);

create table public.clearway_policy_criteria (
  criterion_id text primary key,
  policy_version_id text not null references public.clearway_policy_versions(policy_version_id) on delete cascade,
  criterion_code text not null,
  title text not null,
  description text not null,
  policy_quote text not null,
  policy_locator text not null,
  ordinal integer not null,
  required boolean not null default true,
  unique (policy_version_id, criterion_code)
);

create table public.clearway_review_runs (
  run_id text primary key,
  case_id text not null references public.clearway_prior_auth_cases(case_id) on delete cascade,
  trace_id text not null unique,
  workflow_state text not null check (workflow_state in ('review_ready', 'more_information_required', 'clinical_review_required', 'blocked_invalid_input')),
  state_label text not null,
  state_message text not null,
  result_source text not null default 'precomputed_uat',
  created_at timestamptz not null default now()
);

create table public.clearway_criterion_results (
  run_id text not null references public.clearway_review_runs(run_id) on delete cascade,
  criterion_id text not null references public.clearway_policy_criteria(criterion_id),
  status text not null check (status in ('supported', 'not_evidenced', 'conflicting', 'unable_to_assess', 'not_applicable', 'blocked')),
  clinical_sources jsonb not null default '[]'::jsonb,
  next_action text not null,
  why_flagged text,
  resolved boolean not null default false,
  primary key (run_id, criterion_id),
  check (jsonb_typeof(clinical_sources) = 'array')
);

create table public.clearway_clarifications (
  clarification_id text primary key,
  case_id text not null references public.clearway_prior_auth_cases(case_id) on delete cascade,
  criterion_id text not null references public.clearway_policy_criteria(criterion_id),
  document_id text not null references public.clearway_documents(document_id),
  actor_id text not null,
  actor_role text not null,
  resolution_note text not null,
  created_at timestamptz not null default now(),
  is_synthetic boolean not null default true check (is_synthetic = true)
);

create index clearway_cases_patient_idx on public.clearway_prior_auth_cases(patient_id);
create index clearway_orders_case_idx on public.clearway_orders(case_id);
create index clearway_documents_case_idx on public.clearway_documents(case_id);
create index clearway_review_runs_case_created_idx on public.clearway_review_runs(case_id, created_at desc);
create index clearway_results_run_idx on public.clearway_criterion_results(run_id);

-- UAT-only read access. No anonymous write policy is created.
alter table public.clearway_patients enable row level security;
alter table public.clearway_payers enable row level security;
alter table public.clearway_plans enable row level security;
alter table public.clearway_coverages enable row level security;
alter table public.clearway_policies enable row level security;
alter table public.clearway_policy_versions enable row level security;
alter table public.clearway_prior_auth_cases enable row level security;
alter table public.clearway_orders enable row level security;
alter table public.clearway_documents enable row level security;
alter table public.clearway_policy_criteria enable row level security;
alter table public.clearway_review_runs enable row level security;
alter table public.clearway_criterion_results enable row level security;
alter table public.clearway_clarifications enable row level security;

create policy clearway_uat_read on public.clearway_patients for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_payers for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_plans for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_coverages for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_policies for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_policy_versions for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_prior_auth_cases for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_orders for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_documents for select to anon, authenticated using (is_synthetic);
create policy clearway_uat_read on public.clearway_policy_criteria for select to anon, authenticated using (true);
create policy clearway_uat_read on public.clearway_review_runs for select to anon, authenticated using (true);
create policy clearway_uat_read on public.clearway_criterion_results for select to anon, authenticated using (true);
create policy clearway_uat_read on public.clearway_clarifications for select to anon, authenticated using (is_synthetic);

grant usage on schema public to anon, authenticated;
grant select on public.clearway_patients, public.clearway_payers, public.clearway_plans,
  public.clearway_coverages, public.clearway_policies, public.clearway_policy_versions,
  public.clearway_prior_auth_cases, public.clearway_orders, public.clearway_documents,
  public.clearway_policy_criteria, public.clearway_review_runs,
  public.clearway_criterion_results, public.clearway_clarifications to anon, authenticated;

-- One-row workspace payload consumed by the backend adapter.
create view public.clearway_workspace_payload
with (security_invoker = true)
as
select
  'workspace'::text as workspace_id,
  jsonb_build_object(
    'patients', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', p.patient_id,
        'name', p.display_name,
        'mrn', p.mrn,
        'dateOfBirth', p.date_of_birth
      ) order by p.display_name)
      from public.clearway_patients p
    ), '[]'::jsonb),
    'cases', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', c.case_id,
        'patientId', c.patient_id,
        'orderIds', coalesce((select jsonb_agg(o.order_id order by o.order_id) from public.clearway_orders o where o.case_id = c.case_id), '[]'::jsonb),
        'procedure', (select o.procedure_name from public.clearway_orders o where o.case_id = c.case_id order by o.order_id limit 1),
        'caseType', c.case_type,
        'scenario', c.scenario,
        'statusLabel', case c.scenario
          when 'review_ready' then 'Ready for clinician review'
          when 'needs_documentation' then 'Needs documentation'
          when 'conflicting_evidence' then 'Conflicting evidence'
          else 'Policy validation required'
        end,
        'requestDate', c.request_date
      ) order by c.case_id)
      from public.clearway_prior_auth_cases c
    ), '[]'::jsonb)
  ) as payload;

grant select on public.clearway_workspace_payload to anon, authenticated;

-- Canonical case graph. The backend selects one case_id and returns payload.
create view public.clearway_case_payloads
with (security_invoker = true)
as
select
  c.case_id,
  jsonb_build_object(
    'id', c.case_id,
    'scenario', c.scenario,
    'caseType', c.case_type,
    'requestDate', c.request_date,
    'patient', jsonb_build_object(
      'id', p.patient_id,
      'name', p.display_name,
      'mrn', p.mrn,
      'dateOfBirth', p.date_of_birth
    ),
    'orders', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', o.order_id,
        'procedure', o.procedure_name,
        'procedureCode', o.procedure_code,
        'codeSystem', o.code_system,
        'orderedDate', o.ordered_date,
        'serviceDate', o.service_date,
        'orderingClinician', o.ordering_clinician,
        'status', o.order_status
      ) order by o.order_id)
      from public.clearway_orders o where o.case_id = c.case_id
    ), '[]'::jsonb),
    'selectedOrderId', (select o.order_id from public.clearway_orders o where o.case_id = c.case_id order by o.order_id limit 1),
    'coverage', jsonb_build_object(
      'payer', jsonb_build_object('id', py.payer_id, 'name', py.payer_name),
      'plan', jsonb_build_object('id', pl.plan_id, 'name', pl.plan_name),
      'coverageId', cv.coverage_id,
      'memberId', cv.member_id
    ),
    'policy', jsonb_build_object(
      'id', pol.policy_id,
      'version', pv.version,
      'name', pol.policy_name,
      'effectiveStart', pv.effective_start,
      'effectiveEnd', pv.effective_end,
      'contentHash', pv.content_hash,
      'current', c.request_date between pv.effective_start and pv.effective_end
    ),
    'review', jsonb_build_object(
      'runId', rr.run_id,
      'traceId', rr.trace_id,
      'state', rr.workflow_state,
      'stateLabel', rr.state_label,
      'stateMessage', rr.state_message,
      'resultSource', rr.result_source
    ),
    'documents', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', d.document_id,
        'name', d.title,
        'date', d.display_date,
        'type', d.document_type,
        'present', d.present
      ) order by d.document_id)
      from public.clearway_documents d where d.case_id = c.case_id
    ), '[]'::jsonb),
    'criteria', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', pc.criterion_code,
        'title', pc.title,
        'description', pc.description,
        'status', cr.status,
        'policyQuote', pc.policy_quote,
        'policyLocator', pc.policy_locator,
        'clinicalSources', cr.clinical_sources,
        'next', cr.next_action,
        'whyFlagged', cr.why_flagged,
        'resolved', cr.resolved
      ) order by pc.ordinal)
      from public.clearway_criterion_results cr
      join public.clearway_policy_criteria pc on pc.criterion_id = cr.criterion_id
      where cr.run_id = rr.run_id
    ), '[]'::jsonb)
  ) as payload
from public.clearway_prior_auth_cases c
join public.clearway_patients p on p.patient_id = c.patient_id
join public.clearway_coverages cv on cv.coverage_id = c.coverage_id
join public.clearway_plans pl on pl.plan_id = cv.plan_id
join public.clearway_payers py on py.payer_id = pl.payer_id
join public.clearway_policy_versions pv on pv.policy_version_id = c.policy_version_id
join public.clearway_policies pol on pol.policy_id = pv.policy_id
join lateral (
  select r.* from public.clearway_review_runs r
  where r.case_id = c.case_id
  order by r.created_at desc, r.run_id desc
  limit 1
) rr on true;

grant select on public.clearway_case_payloads to anon, authenticated;

commit;
