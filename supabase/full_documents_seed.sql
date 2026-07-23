-- Adds substantive synthetic clinical source text and full synthetic payer-policy text.
-- No real patient, clinician, facility, or payer information is included.

begin;

create extension if not exists pgcrypto with schema extensions;

alter table public.clearway_documents
  add column if not exists mime_type text,
  add column if not exists document_status text,
  add column if not exists author_name text,
  add column if not exists author_role text,
  add column if not exists facility_name text,
  add column if not exists signed_at timestamptz,
  add column if not exists document_text text,
  add column if not exists text_sha256 text;

alter table public.clearway_policy_versions
  add column if not exists policy_text text,
  add column if not exists policy_text_sha256 text;

-- PA-3001: lumbar MRI; missing provider-directed conservative-treatment documentation.
update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Elena Brooks, MD', author_role = 'Physical Medicine and Rehabilitation',
  facility_name = 'Clearway Synthetic Spine Clinic', signed_at = '2026-07-14T15:42:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT CLINICAL DOCUMENT
Document ID: DOC-3001-NOTE
Document type: Spine clinic progress note
Patient: Morgan Lee | Patient ID: PAT-3001 | MRN: MRN-UAT-83001
Encounter date: July 14, 2026
Author: Elena Brooks, MD
Facility: Clearway Synthetic Spine Clinic
NOTICE: This record is entirely synthetic and is intended only for software testing.

[Paragraph 1 — Reason for visit]
Morgan Lee is a 44-year-old synthetic patient seen for follow-up of low-back pain radiating through the right buttock and lateral calf. The purpose of this visit is to reassess symptoms and determine whether additional diagnostic evaluation is appropriate.

[Paragraph 2 — Onset]
Symptoms began gradually in mid-May 2026 without fall, collision, fever, or other acute event. Pain is described as aching in the lumbar region with intermittent sharp discomfort down the right leg.

[Paragraph 3 — Functional effect]
The patient reports difficulty sitting longer than thirty minutes and has reduced recreational walking from three miles to approximately one mile. Sleep is interrupted two or three nights each week. The patient remains able to work and perform basic self-care.

[Paragraph 4 — Duration]
Low-back pain with right-sided radicular symptoms has persisted for approximately eight weeks.

[Paragraph 5 — Review of prior records]
No prior lumbar MRI is available in the submitted record. A lumbar radiograph from June 2, 2026 describes mild multilevel degenerative change without fracture. That radiograph is not included in the authorization packet as a separate source document.

[Paragraph 6 — Medication]
The patient has intermittently used nonprescription ibuprofen when tolerated. The record does not establish a prescribed dose, continuous treatment interval, or clinician-monitored response.

[Paragraph 7 — Self-directed care]
Patient reports home exercises and nonprescription anti-inflammatory medication. The patient recalls receiving an exercise handout but no dated physical-therapy plan, attendance record, or therapist response assessment is available today.

[Paragraph 8 — Formal therapy]
A referral for physical therapy was placed at this visit. The patient has not yet supplied a physical-therapy evaluation, treatment dates, number of completed visits, or documented response to provider-directed therapy. The authorization team should not infer completion of formal therapy from the reported home exercises.

[Paragraph 9 — Examination]
Gait is steady. Lumbar flexion reproduces right posterior-thigh discomfort. Seated straight-leg raise is positive on the right. Hip flexion, knee extension, ankle dorsiflexion, and plantar flexion are 5/5 bilaterally. Light-touch sensation is mildly reduced over the right lateral calf. Patellar and Achilles reflexes are symmetric.

[Paragraph 10 — Red flags]
No bowel or bladder change, saddle anesthesia, fever, trauma, or progressive motor loss.

[Paragraph 11 — Assessment]
Persistent low-back pain with right lumbar radicular symptoms. Duration and current symptoms are documented. The record available at this visit does not document a completed provider-directed conservative-treatment course with dates and response.

[Paragraph 12 — Plan]
Order lumbar spine MRI without contrast to evaluate persistent radicular symptoms. Begin formal physical therapy and continue activity as tolerated. Authorization staff should request the physical-therapy treatment summary if completed before submission. Return sooner for new weakness or red-flag symptoms.

Electronically signed by Elena Brooks, MD on July 14, 2026 at 15:42 UTC.
SYNTHETIC UAT RECORD — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3001-NOTE';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Elena Brooks, MD', author_role = 'Ordering clinician',
  facility_name = 'Clearway Synthetic Spine Clinic', signed_at = '2026-07-18T14:05:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT ORDER
Document ID: DOC-3001-ORDER
Patient: Morgan Lee | Patient ID: PAT-3001 | MRN: MRN-UAT-83001
Order ID: ORD-3001
Order date: July 18, 2026
Ordering clinician: Elena Brooks, MD
NOTICE: This order is entirely synthetic and is intended only for software testing.

[Order detail]
Lumbar spine MRI without contrast for persistent right lumbar radiculopathy.

Requested procedure: MRI lumbar spine without contrast
Procedure code: CPT 72148
Requested service date: July 29, 2026
Clinical indication: Approximately eight weeks of low-back pain with right-sided radicular symptoms, positive right seated straight-leg raise, and reduced light-touch sensation over the right lateral calf.

Safety screening: No implanted electronic device, retained metallic foreign body, or contrast administration is indicated in this synthetic record. Final imaging safety screening remains the responsibility of the imaging facility.

Authorization note: The order establishes the requested study and indication. It does not establish completion of provider-directed conservative treatment. Review the accompanying clinical note and request the absent treatment summary when required by policy.

Order status: Active
Electronically signed by Elena Brooks, MD on July 18, 2026 at 14:05 UTC.
SYNTHETIC UAT ORDER — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3001-ORDER';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'expected_not_received',
  author_name = null, author_role = null, facility_name = null, signed_at = null,
  document_text = null, text_sha256 = null
where document_id = 'DOC-3001-PT';

-- PA-3002: total knee arthroplasty; complete evidence package.
update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Samuel Ortiz, MD', author_role = 'Orthopedic surgeon',
  facility_name = 'Clearway Synthetic Orthopedics', signed_at = '2026-07-10T17:18:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT CLINICAL DOCUMENT
Document ID: DOC-3002-ORTHO
Document type: Orthopedic surgery consultation
Patient: Taylor Jordan | Patient ID: PAT-3002 | MRN: MRN-UAT-83002
Encounter date: July 10, 2026
Author: Samuel Ortiz, MD
NOTICE: This record is entirely synthetic and is intended only for software testing.

[History]
Taylor Jordan is a 67-year-old synthetic patient with progressively limiting right-knee pain over four years. Pain is present daily, is worse with stairs and standing, and limits walking to approximately two city blocks. The patient uses a cane outside the home and reports difficulty with shopping and household tasks.

[Conservative treatment]
Documented nonoperative management includes a twelve-week supervised physical-therapy course from January 13 through April 7, 2026, activity modification, topical and oral anti-inflammatory therapy when tolerated, and intra-articular injections on February 3 and May 12, 2026. Relief from the most recent injection lasted approximately three weeks. The patient reports no durable functional improvement.

[Imaging reviewed]
Weight-bearing right-knee radiographs dated July 8, 2026 were reviewed and show advanced medial and patellofemoral joint-space loss, osteophytes, and subchondral sclerosis. The imaging report is included as DOC-3002-XRAY.

[Examination]
Antalgic gait is present. Right-knee range of motion is 8 to 108 degrees with crepitus. There is medial joint-line tenderness and a small effusion. Distal motor, sensation, and perfusion are intact. Skin over the planned operative field is intact.

[Assessment]
Severe right-knee osteoarthritis with daily pain and functional limitation.

[Shared decision-making]
The diagnosis, continued conservative care, and surgical options were discussed. Because symptoms remain functionally limiting despite documented nonoperative treatment, the patient wishes to proceed with right total knee arthroplasty. Risks, expected rehabilitation, and the need for medical optimization were reviewed. This document records a synthetic preference for testing and is not consent for an actual procedure.

[Plan]
Request authorization for right total knee arthroplasty, CPT 27447. Obtain medical optimization clearance, confirm operative-site planning, and route the complete evidence package to a clinician for final review.

Electronically signed by Samuel Ortiz, MD on July 10, 2026 at 17:18 UTC.
SYNTHETIC UAT RECORD — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3002-ORTHO';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Lila Mercer, MD', author_role = 'Synthetic radiologist',
  facility_name = 'Clearway Synthetic Imaging', signed_at = '2026-07-08T12:26:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT IMAGING REPORT
Document ID: DOC-3002-XRAY
Patient: Taylor Jordan | Patient ID: PAT-3002 | MRN: MRN-UAT-83002
Study date: July 8, 2026
Study: Right knee radiographs, four views, including weight-bearing views
NOTICE: This report is entirely synthetic and is intended only for software testing.

[Clinical indication]
Chronic right-knee pain, reduced walking tolerance, and preoperative assessment for possible arthroplasty.

[Technique]
Synthetic anteroposterior weight-bearing, lateral, sunrise, and posteroanterior flexion views were evaluated. No actual images exist for this UAT record.

[Findings]
There is severe narrowing of the medial tibiofemoral compartment with near bone-on-bone apposition on the weight-bearing view. Moderate-to-severe patellofemoral joint-space narrowing is also present. Tricompartmental marginal osteophytes and medial subchondral sclerosis are described. No acute fracture, dislocation, or destructive osseous lesion is identified. A small joint effusion is present.

[Impression]
Near-complete medial-compartment joint-space loss with osteophyte formation.
Advanced tricompartmental osteoarthritis, greatest in the medial and patellofemoral compartments. No acute osseous abnormality.

Electronically signed by Lila Mercer, MD on July 8, 2026 at 12:26 UTC.
SYNTHETIC UAT IMAGING REPORT — NO REAL IMAGES OR PATIENT.$doc$
where document_id = 'DOC-3002-XRAY';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Mara Ellis, DPT', author_role = 'Physical therapist',
  facility_name = 'Clearway Synthetic Rehabilitation', signed_at = '2026-07-06T19:10:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT TREATMENT SUMMARY
Document ID: DOC-3002-PT
Patient: Taylor Jordan | Patient ID: PAT-3002 | MRN: MRN-UAT-83002
Treatment interval: January 13 through April 7, 2026
Summary date: July 6, 2026
Author: Mara Ellis, DPT
NOTICE: This record is entirely synthetic and is intended only for software testing.

[Referral and baseline]
The patient was referred for right-knee osteoarthritis with pain during walking, stairs, and sit-to-stand activity. At the initial synthetic evaluation, active right-knee motion was 10 to 105 degrees, quadriceps strength was 4-/5, and the patient tolerated approximately ten minutes of continuous walking.

[Course]
Twelve supervised visits were completed over twelve weeks. Interventions included range-of-motion exercise, quadriceps and hip strengthening, gait training, home exercise instruction, and activity modification. Attendance was consistent. The patient also used anti-inflammatory therapy as directed by the treating clinician.

[Response]
Flexion improved to 110 degrees and quadriceps strength improved to 4+/5. Pain with prolonged standing and stairs remained 7/10. Walking tolerance remained limited to approximately two blocks. Functional improvement was not durable after discharge despite continued home exercise.

[Additional treatment]
The orthopedic record documents injections on February 3 and May 12, 2026. The patient reported temporary relief only.

[Discharge assessment]
Physical therapy, activity modification, NSAID therapy, and two injections provided inadequate durable relief.
The patient reached a plateau in conservative management and was discharged to independent exercise with orthopedic follow-up.

Electronically signed by Mara Ellis, DPT on July 6, 2026 at 19:10 UTC.
SYNTHETIC UAT RECORD — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3002-PT';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Owen Park, MD', author_role = 'Internal medicine clinician',
  facility_name = 'Clearway Synthetic Preoperative Clinic', signed_at = '2026-07-15T16:30:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT PREOPERATIVE CLEARANCE
Document ID: DOC-3002-CLEAR
Patient: Taylor Jordan | Patient ID: PAT-3002 | MRN: MRN-UAT-83002
Evaluation date: July 15, 2026
Planned procedure: Right total knee arthroplasty
NOTICE: This record is entirely synthetic and is intended only for software testing.

[Purpose]
Preoperative medical optimization review for a synthetic planned right total knee arthroplasty. This document does not authorize or schedule a real procedure.

[Medical history]
Synthetic history includes controlled hypertension and hyperlipidemia. There is no documented history of myocardial infarction, heart failure, stroke, insulin-treated diabetes, chronic kidney disease, bleeding disorder, or anesthesia complication. Medication reconciliation was completed for testing purposes.

[Functional and symptom review]
The patient denies chest pain, resting dyspnea, syncope, fever, or active infection. Functional activity is limited primarily by knee pain. No open skin lesion is present over the operative extremity.

[Examination]
Blood pressure 128/76, pulse 72, and oxygen saturation 98% on room air are synthetic values. Heart rhythm is regular, lungs are clear, and there is no acute cardiopulmonary finding.

[Testing]
Synthetic CBC and basic metabolic panel are within the stated reference limits. Creatinine is 0.9 mg/dL and hemoglobin is 13.8 g/dL. Electrocardiogram shows sinus rhythm without an acute ischemic pattern. No additional preoperative test is identified in this bounded UAT review.

[Assessment and plan]
Patient is medically optimized for planned right total knee arthroplasty.
Medication and perioperative instructions were reviewed in synthetic form. Final surgical, anesthesia, and perioperative decisions remain with the responsible clinicians.

Electronically signed by Owen Park, MD on July 15, 2026 at 16:30 UTC.
SYNTHETIC UAT CLEARANCE — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3002-CLEAR';

-- PA-3003: lumbar fusion; intentionally contradictory neurologic findings.
update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Priya Nair, MD', author_role = 'Spine surgeon',
  facility_name = 'Clearway Synthetic Spine Surgery', signed_at = '2026-07-11T18:02:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT CLINICAL DOCUMENT
Document ID: DOC-3003-SPINE
Document type: Spine surgery consultation
Patient: Avery Patel | Patient ID: PAT-3003 | MRN: MRN-UAT-83003
Encounter date: July 11, 2026
Author: Priya Nair, MD
NOTICE: This record is entirely synthetic and is intended only for software testing.

[History]
Avery Patel is a 55-year-old synthetic patient with fourteen months of low-back pain and right-greater-than-left leg symptoms. Pain limits standing to fifteen minutes and walking to approximately one block. No bowel or bladder change is reported.

[Nonoperative management]
The record documents seven months of structured nonoperative care from December 2025 through June 2026, including supervised physical therapy, anti-inflammatory medication when tolerated, neuropathic-pain medication, activity modification, and two image-guided injections. Symptoms and functional limitation persisted.

[Imaging reviewed]
Lumbar MRI is described as showing L4-L5 degenerative stenosis. Flexion-extension radiographs dated July 9, 2026 show dynamic L4-L5 translation consistent with instability. The requested and planned fusion level is L4-L5.

[Neurologic exam]
Gait is antalgic. Hip flexion and knee extension are 5/5 bilaterally. Right ankle dorsiflexion is 4/5. Left ankle dorsiflexion and bilateral plantar flexion are 5/5. Sensation is reduced over the right lateral calf. Patellar reflexes are 2+ and symmetric.

[Assessment]
L4-L5 degenerative stenosis and dynamic instability with persistent functional limitation despite documented nonoperative care. The right ankle dorsiflexion finding is used as part of the surgical assessment in this note.

[Plan]
Planned posterolateral fusion at L4-L5.
The risks, alternatives, expected recovery, and need for final medical review were discussed in synthetic form. Request prior authorization for CPT 22612. The authorization package should include imaging, treatment history, and current neurologic documentation.

Electronically signed by Priya Nair, MD on July 11, 2026 at 18:02 UTC.
SYNTHETIC UAT RECORD — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3003-SPINE';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Jonas Reed, MD', author_role = 'Neurologist',
  facility_name = 'Clearway Synthetic Neurology', signed_at = '2026-07-12T15:24:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT CLINICAL DOCUMENT
Document ID: DOC-3003-NEURO
Document type: Independent neurologic examination
Patient: Avery Patel | Patient ID: PAT-3003 | MRN: MRN-UAT-83003
Encounter date: July 12, 2026
Author: Jonas Reed, MD
NOTICE: This record is entirely synthetic and is intended only for software testing.

[Reason for examination]
Focused neurologic assessment for lumbar pain with intermittent right-leg symptoms. The examiner reviewed the reason for referral but did not reconcile findings with the prior-day spine surgery note.

[Symptoms]
The patient reports low-back pain and intermittent right lateral-calf paresthesia. No new fall, bowel or bladder change, or saddle anesthesia is reported.

[Motor examination]
Effort is described as consistent. Hip flexion, knee extension, ankle dorsiflexion, great-toe extension, and plantar flexion are tested bilaterally.

Bilateral ankle dorsiflexion is 5/5 without focal weakness.
Hip flexion, knee extension, great-toe extension, and plantar flexion are also 5/5 bilaterally.

[Sensory and reflex examination]
Light-touch sensation is mildly reduced over the right lateral calf. Patellar and Achilles reflexes are 2+ and symmetric. No clonus is present. Gait is mildly antalgic but stable without assistive equipment during the examination.

[Assessment]
Lumbar pain with intermittent right sensory symptoms. No focal motor deficit is identified in this examination.

[Important UAT note]
This result intentionally conflicts with DOC-3003-SPINE, which records right ankle dorsiflexion as 4/5 one day earlier. No explanation or signed correction is provided. The workflow must preserve both statements and request authorized clinician clarification rather than selecting one as true.

Electronically signed by Jonas Reed, MD on July 12, 2026 at 15:24 UTC.
SYNTHETIC UAT RECORD — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3003-NEURO';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Lila Mercer, MD', author_role = 'Synthetic radiologist',
  facility_name = 'Clearway Synthetic Imaging', signed_at = '2026-07-09T13:48:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT IMAGING REPORT
Document ID: DOC-3003-IMG
Patient: Avery Patel | Patient ID: PAT-3003 | MRN: MRN-UAT-83003
Study date: July 9, 2026
Study: Lumbar flexion-extension radiographs
NOTICE: This report is entirely synthetic and is intended only for software testing.

[Clinical indication]
Chronic low-back pain, suspected L4-L5 instability, and preoperative evaluation.

[Technique]
Synthetic standing lateral flexion and extension views of the lumbar spine were evaluated. No actual images exist for this UAT record.

[Findings]
There is grade 1 anterolisthesis of L4 on L5. Translation increases from approximately 3 mm in extension to approximately 7 mm in flexion. Disc-space narrowing and facet degenerative change are greatest at L4-L5. Vertebral body heights are maintained. No acute compression fracture is identified.

[Impression]
Dynamic L4-L5 translation is consistent with segmental instability.
Degenerative change is greatest at L4-L5. Correlation with the clinical examination and existing cross-sectional imaging is recommended.

Electronically signed by Lila Mercer, MD on July 9, 2026 at 13:48 UTC.
SYNTHETIC UAT IMAGING REPORT — NO REAL IMAGES OR PATIENT.$doc$
where document_id = 'DOC-3003-IMG';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Mara Ellis, DPT', author_role = 'Physical therapist',
  facility_name = 'Clearway Synthetic Rehabilitation', signed_at = '2026-07-07T19:36:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT TREATMENT SUMMARY
Document ID: DOC-3003-TX
Patient: Avery Patel | Patient ID: PAT-3003 | MRN: MRN-UAT-83003
Treatment interval: December 2, 2025 through June 30, 2026
Summary date: July 7, 2026
NOTICE: This record is entirely synthetic and is intended only for software testing.

[Initial presentation]
The patient entered supervised therapy for chronic low-back pain with intermittent right-leg symptoms, limited standing, and reduced walking tolerance.

[Documented treatment]
The seven-month record contains twenty supervised physical-therapy visits, a progressive home exercise program, core stabilization, mobility work, gait and body-mechanics training, and activity modification. The treating-clinician record also documents anti-inflammatory medication when tolerated, neuropathic-pain medication, and image-guided injections on February 18 and May 20, 2026.

[Response]
The patient demonstrated modest improvement in trunk mobility but continued to report pain with standing longer than fifteen minutes and walking farther than one block. Each injection produced less than four weeks of partial relief. Functional limitations persisted at discharge.

[Summary]
Seven months of physical therapy, medication management, and two injections produced persistent functional limitation.
No durable improvement sufficient to meet the patient's stated activity goals was documented.

[Disposition]
Discharged to an independent maintenance program with return to the spine clinician. This treatment summary does not resolve the contradictory motor-strength findings recorded in separate July clinical notes.

Electronically signed by Mara Ellis, DPT on July 7, 2026 at 19:36 UTC.
SYNTHETIC UAT RECORD — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3003-TX';

-- PA-3004: adalimumab; missing tuberculosis-screening result.
update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Marcus Hale, MD', author_role = 'Rheumatologist',
  facility_name = 'Clearway Synthetic Rheumatology', signed_at = '2026-07-16T20:12:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT CLINICAL DOCUMENT
Document ID: DOC-3004-RHEUM
Document type: Rheumatology treatment note
Patient: Casey Kim | Patient ID: PAT-3004 | MRN: MRN-UAT-83004
Encounter date: July 16, 2026
Author: Marcus Hale, MD
NOTICE: This record is entirely synthetic and is intended only for software testing.

[Diagnosis and current status]
Casey Kim is a 36-year-old synthetic patient followed for seropositive rheumatoid arthritis. The record describes symmetric hand and wrist synovitis, morning stiffness lasting approximately ninety minutes, and persistent difficulty with gripping and keyboard work.

Seropositive rheumatoid arthritis remains moderately active.

[Prior therapy]
Methotrexate was initiated March 5, 2026 and increased to a therapeutic weekly dose with folic-acid supplementation. Adherence is documented over four months. The patient reports modest improvement in morning stiffness but persistent swollen joints and functional limitation.

Methotrexate was used for four months at a therapeutic dose with inadequate response.

[Current examination]
Synthetic examination records tenderness and swelling in multiple metacarpophalangeal and proximal interphalangeal joints. No active fever, productive cough, open wound, or other acute infection symptom is reported.

[Safety review]
Baseline CBC and liver panel were collected July 17, 2026 and are available as DOC-3004-LABS. Tuberculosis screening was ordered, but no specimen result, laboratory report, or documented negative test is available in the submitted packet. Hepatitis-screening assumptions must not be inferred beyond this synthetic case's defined criteria.

[Assessment]
Moderately active seropositive rheumatoid arthritis despite an adequate methotrexate trial. Adalimumab is proposed as the next therapy, subject to coverage review and completion of required safety screening.

[Plan]
Submit the diagnosis, prior-therapy history, baseline laboratory results, and medication order for authorization review. Do not initiate the synthetic therapy workflow until a current tuberculosis screening result is documented and reviewed.

Electronically signed by Marcus Hale, MD on July 16, 2026 at 20:12 UTC.
SYNTHETIC UAT RECORD — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3004-RHEUM';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Clearway Synthetic Laboratory', author_role = 'Laboratory service',
  facility_name = 'Clearway Synthetic Laboratory', signed_at = '2026-07-17T14:32:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT LABORATORY REPORT
Document ID: DOC-3004-LABS
Patient: Casey Kim | Patient ID: PAT-3004 | MRN: MRN-UAT-83004
Collection date: July 17, 2026
Report date: July 17, 2026
NOTICE: This report is entirely synthetic and is intended only for software testing.

[Complete blood count]
White blood cell count: 6.4 x10^3/uL (synthetic reference 4.0–10.5)
Hemoglobin: 13.4 g/dL (synthetic reference 12.0–16.0)
Platelet count: 268 x10^3/uL (synthetic reference 150–400)
Absolute neutrophil count: 3.7 x10^3/uL (synthetic reference 1.5–7.5)

[Hepatic panel]
AST: 24 U/L (synthetic reference 10–40)
ALT: 27 U/L (synthetic reference 7–45)
Alkaline phosphatase: 79 U/L (synthetic reference 40–120)
Total bilirubin: 0.6 mg/dL (synthetic reference 0.2–1.2)
Albumin: 4.2 g/dL (synthetic reference 3.5–5.0)

[Result summary]
Blood counts and hepatic-function values are within the documented treatment parameters.
No critical value is present in this synthetic report.

[Important limitation]
This report does not contain a tuberculosis screening assay. A separate tuberculosis screening result was expected but was not received. The absence of that result must not be interpreted as a negative test.

Electronically authenticated by Clearway Synthetic Laboratory on July 17, 2026 at 14:32 UTC.
SYNTHETIC UAT LABORATORY REPORT — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3004-LABS';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Marcus Hale, MD', author_role = 'Ordering clinician',
  facility_name = 'Clearway Synthetic Rheumatology', signed_at = '2026-07-19T15:14:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT MEDICATION ORDER
Document ID: DOC-3004-ORDER
Patient: Casey Kim | Patient ID: PAT-3004 | MRN: MRN-UAT-83004
Order ID: ORD-3004
Order date: July 19, 2026
Ordering clinician: Marcus Hale, MD
NOTICE: This order is entirely synthetic and is intended only for software testing.

[Medication order]
Adalimumab induction and maintenance.
HCPCS code: J0135
Indication: Moderately active seropositive rheumatoid arthritis with inadequate response to four months of therapeutic-dose methotrexate.
Requested service date: July 30, 2026.

[Pre-initiation conditions]
Coverage authorization and clinician review are required. Baseline CBC and hepatic panel are available. A current tuberculosis screening result must be documented and reviewed before initiation. The order itself is not evidence that tuberculosis screening was completed or negative.

[Status]
Pending authorization and completion of safety-documentation requirements. No medication administration is represented by this synthetic order.

Electronically signed by Marcus Hale, MD on July 19, 2026 at 15:14 UTC.
SYNTHETIC UAT ORDER — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3004-ORDER';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'expected_not_received',
  author_name = null, author_role = null, facility_name = null, signed_at = null,
  document_text = null, text_sha256 = null
where document_id = 'DOC-3004-TB';

-- PA-3005: CPAP/DME; complete initial-coverage evidence package.
update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Nina Shah, MD', author_role = 'Sleep medicine physician',
  facility_name = 'Clearway Synthetic Sleep Center', signed_at = '2026-07-09T13:06:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT SLEEP-STUDY REPORT
Document ID: DOC-3005-SLEEP
Patient: Jordan Rivera | Patient ID: PAT-3005 | MRN: MRN-UAT-83005
Study date: July 9, 2026
Study type: Attended diagnostic polysomnography
NOTICE: This report is entirely synthetic and is intended only for software testing. No actual physiologic recording exists.

[Indication]
Loud snoring, witnessed apneas, nonrestorative sleep, and excessive daytime sleepiness.

[Recording summary]
Synthetic total recording time is 438 minutes and synthetic total sleep time is 376 minutes. Sleep efficiency is 86%. Respiratory events are scored using the test policy's stated UAT conventions.

[Respiratory findings]
There are 138 synthetic apneas and hypopneas, producing an apnea-hypopnea index of 22 events per hour. The index is higher during supine sleep. Oxygen saturation nadir is 84%, with 11 minutes below 90%. No central-apnea predominance is described.

[Cardiac and movement findings]
Synthetic average sleeping heart rate is 68 beats per minute without a sustained arrhythmia. No clinically significant periodic-limb-movement pattern is described in this bounded report.

[Interpretation]
Apnea-hypopnea index is 22 events per hour, consistent with moderate obstructive sleep apnea.
The result meets the synthetic policy threshold for an initial PAP trial when paired with the treating-clinician documentation and complete equipment order.

[Recommendation]
Clinical correlation and PAP treatment planning are recommended. Final equipment selection, education, and follow-up remain clinician responsibilities.

Electronically signed by Nina Shah, MD on July 9, 2026 at 13:06 UTC.
SYNTHETIC UAT SLEEP-STUDY REPORT — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3005-SLEEP';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Nina Shah, MD', author_role = 'Sleep medicine physician',
  facility_name = 'Clearway Synthetic Sleep Center', signed_at = '2026-07-12T16:48:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT CLINICAL DOCUMENT
Document ID: DOC-3005-NOTE
Document type: Sleep medicine consultation
Patient: Jordan Rivera | Patient ID: PAT-3005 | MRN: MRN-UAT-83005
Encounter date: July 12, 2026
Author: Nina Shah, MD
NOTICE: This record is entirely synthetic and is intended only for software testing.

[History]
Jordan Rivera is a 60-year-old synthetic patient referred after an attended sleep study. The patient reports loud habitual snoring, nonrestorative sleep, morning headache twice weekly, and unintended dozing while reading in the afternoon. A household observer reports pauses in breathing during sleep.

Patient reports excessive daytime sleepiness and witnessed apneas.

[Sleep-study review]
The July 9, 2026 synthetic polysomnography report documents an apnea-hypopnea index of 22 events per hour and an oxygen saturation nadir of 84%, consistent with moderate obstructive sleep apnea.

[Relevant examination]
Synthetic body-mass index is 31 kg/m2. Upper-airway examination is described as crowded. Heart rhythm is regular and lungs are clear. No active cardiopulmonary instability is described.

[Assessment]
Moderate obstructive sleep apnea supported by the diagnostic study and clinical symptoms.

[Plan]
Begin an initial auto-adjusting CPAP trial at 6–14 cm H2O with humidification and mask supplies. Provide equipment education and arrange follow-up within sixty to ninety days. Objective adherence is relevant to continued coverage after the initial trial and is not expected before initial equipment delivery.

[Human-review note]
The sleep study, symptoms, and signed equipment order are available for authorization review. This note does not represent payer approval or equipment delivery.

Electronically signed by Nina Shah, MD on July 12, 2026 at 16:48 UTC.
SYNTHETIC UAT RECORD — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3005-NOTE';

update public.clearway_documents set
  mime_type = 'text/plain', document_status = 'received',
  author_name = 'Nina Shah, MD', author_role = 'Ordering clinician',
  facility_name = 'Clearway Synthetic Sleep Center', signed_at = '2026-07-15T14:22:00Z',
  document_text = $doc$CLEARWAY SYNTHETIC UAT DME ORDER
Document ID: DOC-3005-ORDER
Patient: Jordan Rivera | Patient ID: PAT-3005 | MRN: MRN-UAT-83005
Order ID: ORD-3005
Order date: July 15, 2026
Ordering clinician: Nina Shah, MD
NOTICE: This order is entirely synthetic and is intended only for software testing.

[Order detail]
Auto-adjusting CPAP prescribed at 6–14 cm H2O with humidification and mask supplies.

Device: Auto-adjusting continuous positive airway pressure device
HCPCS: E0601
Accessories: Heated humidifier, patient-selected mask interface, tubing, filters, and initial replacement supplies according to the synthetic plan schedule
Indication: Moderate obstructive sleep apnea documented by July 9, 2026 attended polysomnography; AHI 22 events per hour
Requested service date: July 28, 2026
Length of need: 99 months for UAT display only; not a real medical determination

[Follow-up]
Arrange clinical follow-up within sixty to ninety days of synthetic setup. Continued-coverage criteria, including objective adherence, apply after the initial trial and are not represented as already satisfied.

Order status: Active; authorization pending
Electronically signed by Nina Shah, MD on July 15, 2026 at 14:22 UTC.
SYNTHETIC UAT DME ORDER — NOT FOR CLINICAL CARE.$doc$
where document_id = 'DOC-3005-ORDER';

-- Full synthetic policy documents. Exact criterion quotes are embedded verbatim.
update public.clearway_policy_versions set policy_text = $policy$CLEARWAY SYNTHETIC UAT PAYER POLICY
Policy: IMG-MRI-101 — Advanced Imaging: Lumbar Spine MRI
Version: 2026.1 | Effective: January 1–December 31, 2026
Fictional payer: Summit Health Plan
NOTICE: This policy is entirely synthetic. It is not a real coverage policy and must not be used for patient care, payment, or benefit interpretation.

[Page 1 — Purpose and scope]
This policy defines the synthetic evidence needed to route a non-emergent lumbar-spine MRI request for clinician review. It supports software testing only. Meeting a criterion does not constitute authorization, and missing information does not constitute denial.

[Page 2 — Section 1.3: Order and indication]
The order must identify the requested MRI study and the documented clinical indication.
The requested code, anatomic region, contrast status, and clinical reason must be consistent across the order and submitted clinical record.

[Page 2 — Section 1.4: Red-flag exception]
Red-flag findings may bypass conservative-treatment duration requirements.
Examples for this synthetic policy include documented progressive motor loss, cauda-equina features, suspected infection, acute major trauma, or another specifically recorded urgent condition. The workflow must not infer a red flag from silence.

[Page 3 — Section 2.1: Symptom duration]
Symptoms persist for at least six weeks despite initial conservative management.
The source record should identify symptom onset or duration and the relevant functional or neurologic complaint.

[Page 4 — Section 2.2: Conservative management]
The record must document at least six weeks of provider-directed conservative treatment and response.
The treatment record should include dates, modality, clinician direction, and the patient's response. A statement that the patient performed home exercise or used nonprescription medication, without a dated provider-directed course and response, is not sufficient for this synthetic requirement.

[Page 5 — Documentation and workflow]
Required submission elements are the signed order, relevant clinical note, and treatment documentation unless a documented exception applies. Evidence must be linked to source document IDs and locations. A model may classify evidence, but trusted code must validate citations and derive the workflow state. Conflicting clinical statements require clinician clarification.

[Page 6 — Limitations]
This policy does not define medical necessity, payer approval, or clinical appropriateness. It exists only to test evidence extraction, citation, missing-information detection, and human review.$policy$
where policy_version_id = 'IMG-MRI-101:2026.1';

update public.clearway_policy_versions set policy_text = $policy$CLEARWAY SYNTHETIC UAT PAYER POLICY
Policy: SURG-TKA-210 — Total Knee Arthroplasty
Version: 2026.1 | Effective: January 1–December 31, 2026
Fictional payer: Summit Health Plan
NOTICE: This policy is entirely synthetic and must not be used for real coverage or clinical decisions.

[Page 1 — Purpose]
This policy defines the synthetic evidence package used to route a primary total-knee-arthroplasty request for clinician review. Criterion satisfaction is evidence readiness, not authorization.

[Page 3 — Section 2.1: Diagnosis]
The record must show advanced symptomatic osteoarthritis of the operative knee.
The signed orthopedic assessment should identify laterality, symptoms, functional limitation, and the operative diagnosis.

[Page 3 — Section 2.2: Imaging]
Weight-bearing radiographs must demonstrate advanced joint-space loss or equivalent disease.
The imaging report must identify laterality and a finding consistent with the operative diagnosis. A procedure request without linked imaging is incomplete for this synthetic policy.

[Page 4 — Section 2.3: Nonoperative management]
A clinically appropriate trial of nonoperative management must be documented.
The record should identify modalities, treatment dates or duration, and response. Examples include supervised therapy, medication when appropriate, activity modification, assistive-device use, or injection therapy.

[Page 5 — Section 3.1: Optimization]
The record must include medical optimization and surgical risk review.
The clearance document should be signed and should identify whether unresolved conditions require additional review. It does not replace surgical or anesthesia judgment.

[Page 6 — Submission and validation]
The package should include a signed surgical consultation, weight-bearing imaging report, conservative-treatment history, and optimization review. Each criterion result must cite the supporting source. Contradictions, invalid identifiers, or cross-patient evidence stop automatic progression.

[Page 7 — Limitations]
This fictional policy demonstrates evidence-readiness workflow only. It does not approve surgery, establish benefits, or replace clinician review.$policy$
where policy_version_id = 'SURG-TKA-210:2026.1';

update public.clearway_policy_versions set policy_text = $policy$CLEARWAY SYNTHETIC UAT PAYER POLICY
Policy: SURG-LSF-310 — Lumbar Spinal Fusion
Version: 2026.1 | Effective: January 1–December 31, 2026
Fictional payer: Summit Health Plan
NOTICE: This policy is entirely synthetic and must not be used for real coverage or clinical decisions.

[Page 1 — Purpose and scope]
This policy defines a synthetic evidence package for lumbar fusion requests. It is designed to test relationship validation, policy-version pinning, source citation, and conflict handling.

[Page 3 — Section 2.1: Structural indication]
Imaging must demonstrate instability or another covered structural indication.
The imaging source should identify the involved level and finding. The service request must match the documented anatomy.

[Page 4 — Section 2.2: Nonoperative management]
At least six months of clinically appropriate nonoperative treatment must be documented unless an exception applies.
The record should state the treatment interval, modalities, and response. The workflow must not count an undocumented or self-reported course as completed treatment.

[Page 4 — Section 2.3: Neurologic consistency]
Objective neurologic findings used to support surgery must be consistent across the submitted record.
When two signed source documents disagree about the same motor, sensory, or reflex finding, the criterion status is conflicting. The system must display both statements and request authorized clinician clarification; it must not choose the statement it considers more plausible.

[Page 5 — Section 3.1: Operative levels]
The requested fusion levels must be consistent across the order and surgical plan.
Any mismatch in level, laterality, or procedure code blocks progression pending correction.

[Page 6 — Required records]
The synthetic package includes the signed surgical consultation, imaging evidence, nonoperative-treatment history, requested procedure, and relevant focused examinations. Every extracted claim requires a document ID and source location. Original evidence remains immutable when a clarification is added.

[Page 7 — Limitations]
Criterion classification is decision support only. A clinician owns interpretation, clarification, and any next action. This policy does not approve surgery or represent a real payer requirement.$policy$
where policy_version_id = 'SURG-LSF-310:2026.1';

update public.clearway_policy_versions set policy_text = $policy$CLEARWAY SYNTHETIC UAT PAYER POLICY
Policy: RX-ADL-410 — Adalimumab Initial Therapy
Version: 2026.1 | Effective: January 1–December 31, 2026
Fictional payer: Summit Health Plan
NOTICE: This policy is entirely synthetic and must not be used for prescribing, safety, or coverage decisions.

[Page 1 — Purpose]
This policy defines the synthetic evidence required to route an initial adalimumab request for clinician review. It does not establish clinical appropriateness or authorization.

[Page 2 — Section 1.2: Covered diagnosis]
Moderate-to-severe rheumatoid arthritis is a covered indication when documented by the treating specialist.
The signed record should identify the diagnosis and current disease activity.

[Page 3 — Section 2.1: Prior therapy]
The record must document an adequate trial and response to covered conventional therapy unless contraindicated.
The source should identify the medication, treatment interval or duration, therapeutic dosing when relevant, and response or contraindication.

[Page 4 — Section 3.1: Baseline laboratory review]
Baseline complete blood count and liver-function results must be reviewed before therapy.
The actual laboratory report or a validated linked result must be present. An order for testing is not a result.

[Page 4 — Section 3.2: Tuberculosis screening]
A negative tuberculosis screening result must be documented before initiation.
A note that screening was ordered, planned, or pending is not evidence of a negative result. Absence of a result must be classified as not evidenced, not assumed negative.

[Page 5 — Submission and safety boundary]
The package should include the specialist note, prior-therapy evidence, baseline laboratory report, current tuberculosis screening result, and signed medication order. The workflow may identify missing evidence but must not prescribe, administer, or recommend bypassing a safety requirement.

[Page 6 — Limitations]
This fictional policy is for synthetic workflow testing only. Medication selection, contraindication assessment, infection risk, dosing, and monitoring remain outside the model's authority.$policy$
where policy_version_id = 'RX-ADL-410:2026.1';

update public.clearway_policy_versions set policy_text = $policy$CLEARWAY SYNTHETIC UAT PAYER POLICY
Policy: DME-CPAP-510 — Positive Airway Pressure Equipment
Version: 2026.1 | Effective: January 1–December 31, 2026
Fictional payer: Summit Health Plan
NOTICE: This policy is entirely synthetic and must not be used for real equipment, benefit, or clinical decisions.

[Page 1 — Purpose]
This policy defines the synthetic evidence package for an initial positive-airway-pressure equipment request and distinguishes initial from continued-coverage evidence.

[Page 2 — Section 1.1: Qualifying study]
A qualifying sleep study must document the apnea-hypopnea index or respiratory-disturbance index.
The signed study should identify the test date, index value, interpretation, and enough information to match the patient and order.

[Page 2 — Section 1.2: Symptoms or comorbidity]
The clinical record must document qualifying symptoms or covered comorbid conditions.
Examples in this synthetic policy include excessive daytime sleepiness, witnessed apneas, impaired cognition, mood disorder, insomnia, hypertension, ischemic heart disease, or prior stroke. The workflow must cite the submitted source.

[Page 3 — Section 2.1: Equipment order]
A treating clinician order must identify the PAP device and prescribed settings.
The order should include the device type, pressure or range, accessories when relevant, diagnosis, and requested service date.

[Page 4 — Section 3.1: Continued coverage]
Objective adherence is required for continued coverage after the initial trial.
Adherence is not expected before initial setup and should be classified as not applicable for an initial request. The model must not mark a criterion missing when the policy says it applies only later.

[Page 5 — Submission and validation]
The initial package should include the signed sleep study, treating-clinician note, and complete equipment order. Sources must match the same patient and case. Invalid IDs or mixed-case evidence block progression.

[Page 6 — Limitations]
This fictional policy demonstrates evidence review only. It does not establish equipment eligibility, approve payment, select a device, or replace clinician and supplier responsibilities.$policy$
where policy_version_id = 'DME-CPAP-510:2026.1';

-- Compute content hashes from the actual synthetic text.
update public.clearway_documents
set text_sha256 = encode(extensions.digest(convert_to(document_text, 'UTF8'), 'sha256'), 'hex'),
    content_hash = 'sha256:' || encode(extensions.digest(convert_to(document_text, 'UTF8'), 'sha256'), 'hex')
where present and document_text is not null;

update public.clearway_policy_versions
set policy_text_sha256 = encode(extensions.digest(convert_to(policy_text, 'UTF8'), 'sha256'), 'hex'),
    content_hash = 'sha256:' || encode(extensions.digest(convert_to(policy_text, 'UTF8'), 'sha256'), 'hex')
where policy_text is not null;

alter table public.clearway_documents alter column mime_type set default 'text/plain';

do $constraints$
begin
  -- Migrations run before seeds on a fresh Supabase project. Apply strict
  -- constraints only when the base synthetic records are already present;
  -- the ordered full-document seed reruns this file after base seeding.
  if exists (select 1 from public.clearway_documents) then
    alter table public.clearway_documents alter column mime_type set not null;
    alter table public.clearway_documents alter column document_status set not null;
    alter table public.clearway_documents drop constraint if exists clearway_documents_status_check;
    alter table public.clearway_documents drop constraint if exists clearway_documents_text_presence_check;
    alter table public.clearway_documents
      add constraint clearway_documents_status_check
        check (document_status in ('received', 'expected_not_received')),
      add constraint clearway_documents_text_presence_check
        check (
          (present and document_status = 'received' and document_text is not null and length(document_text) >= 250)
          or
          (not present and document_status = 'expected_not_received' and document_text is null)
        );

    alter table public.clearway_policy_versions drop constraint if exists clearway_policy_text_check;
    alter table public.clearway_policy_versions
      add constraint clearway_policy_text_check
        check (policy_text is not null and length(policy_text) >= 500);
  end if;
end
$constraints$;

-- Backend-only logical input bundle. It is not routed to the browser UI.
drop view if exists public.clearway_ai_case_inputs;
create view public.clearway_ai_case_inputs
with (security_invoker = true)
as
select
  c.case_id,
  jsonb_build_object(
    'schemaVersion', 'clearway.ai-input.v1',
    'synthetic', true,
    'case', jsonb_build_object(
      'caseId', c.case_id,
      'caseType', c.case_type,
      'requestDate', c.request_date,
      'patient', jsonb_build_object(
        'patientId', p.patient_id,
        'displayName', p.display_name,
        'mrn', p.mrn,
        'dateOfBirth', p.date_of_birth
      ),
      'coverage', jsonb_build_object(
        'coverageId', cv.coverage_id,
        'payerId', py.payer_id,
        'payerName', py.payer_name,
        'planId', pl.plan_id,
        'planName', pl.plan_name,
        'memberId', cv.member_id
      ),
      'order', (
        select jsonb_build_object(
          'orderId', o.order_id,
          'procedure', o.procedure_name,
          'procedureCode', o.procedure_code,
          'codeSystem', o.code_system,
          'orderedDate', o.ordered_date,
          'serviceDate', o.service_date,
          'orderingClinician', o.ordering_clinician
        )
        from public.clearway_orders o
        where o.case_id = c.case_id
        order by o.order_id
        limit 1
      )
    ),
    'policy', jsonb_build_object(
      'policyId', pol.policy_id,
      'policyVersionId', pv.policy_version_id,
      'version', pv.version,
      'effectiveStart', pv.effective_start,
      'effectiveEnd', pv.effective_end,
      'contentHash', pv.content_hash,
      'policyText', pv.policy_text,
      'criteria', coalesce((
        select jsonb_agg(jsonb_build_object(
          'criterionId', pc.criterion_id,
          'criterionCode', pc.criterion_code,
          'title', pc.title,
          'description', pc.description,
          'policyQuote', pc.policy_quote,
          'policyLocator', pc.policy_locator,
          'required', pc.required
        ) order by pc.ordinal)
        from public.clearway_policy_criteria pc
        where pc.policy_version_id = pv.policy_version_id
      ), '[]'::jsonb)
    ),
    'documentManifest', coalesce((
      select jsonb_agg(jsonb_build_object(
        'documentId', d.document_id,
        'documentType', d.document_type,
        'title', d.title,
        'documentDate', d.document_date,
        'status', d.document_status,
        'present', d.present,
        'contentHash', d.content_hash
      ) order by d.document_id)
      from public.clearway_documents d
      where d.case_id = c.case_id
    ), '[]'::jsonb),
    'sourceDocuments', coalesce((
      select jsonb_agg(jsonb_build_object(
        'documentId', d.document_id,
        'documentType', d.document_type,
        'title', d.title,
        'documentDate', d.document_date,
        'authorName', d.author_name,
        'authorRole', d.author_role,
        'facilityName', d.facility_name,
        'signedAt', d.signed_at,
        'mimeType', d.mime_type,
        'contentHash', d.content_hash,
        'text', d.document_text
      ) order by d.document_id)
      from public.clearway_documents d
      where d.case_id = c.case_id and d.present
    ), '[]'::jsonb)
  ) as payload
from public.clearway_prior_auth_cases c
join public.clearway_patients p on p.patient_id = c.patient_id
join public.clearway_coverages cv on cv.coverage_id = c.coverage_id
join public.clearway_plans pl on pl.plan_id = cv.plan_id
join public.clearway_payers py on py.payer_id = pl.payer_id
join public.clearway_policy_versions pv on pv.policy_version_id = c.policy_version_id
join public.clearway_policies pol on pol.policy_id = pv.policy_id;

grant select on public.clearway_ai_case_inputs to anon, authenticated;

-- Migration gates: no empty present documents, missing records remain absent,
-- every displayed evidence quote occurs verbatim in its source, and every
-- policy criterion quote occurs verbatim in the pinned policy text.
do $verify$
declare
  quote_failure_count integer;
begin
  if exists (select 1 from public.clearway_prior_auth_cases) then
    if (select count(*) from public.clearway_documents where present) <> 16 then
    raise exception 'Expected 16 present synthetic documents';
  end if;

  if exists (
    select 1 from public.clearway_documents
    where present and (document_text is null or length(document_text) < 250 or text_sha256 is null)
  ) then
    raise exception 'A present document is missing substantive text or hash';
  end if;

  if exists (
    select 1 from public.clearway_documents
    where not present and document_text is not null
  ) then
    raise exception 'An expected-not-received document incorrectly contains text';
  end if;

  select count(*) into quote_failure_count
  from (values
    ('DOC-3001-NOTE', 'Low-back pain with right-sided radicular symptoms has persisted for approximately eight weeks.'),
    ('DOC-3001-NOTE', 'Patient reports home exercises and nonprescription anti-inflammatory medication.'),
    ('DOC-3001-NOTE', 'No bowel or bladder change, saddle anesthesia, fever, trauma, or progressive motor loss.'),
    ('DOC-3001-ORDER', 'Lumbar spine MRI without contrast for persistent right lumbar radiculopathy.'),
    ('DOC-3002-ORTHO', 'Severe right-knee osteoarthritis with daily pain and functional limitation.'),
    ('DOC-3002-XRAY', 'Near-complete medial-compartment joint-space loss with osteophyte formation.'),
    ('DOC-3002-PT', 'Physical therapy, activity modification, NSAID therapy, and two injections provided inadequate durable relief.'),
    ('DOC-3002-CLEAR', 'Patient is medically optimized for planned right total knee arthroplasty.'),
    ('DOC-3003-IMG', 'Dynamic L4-L5 translation is consistent with segmental instability.'),
    ('DOC-3003-TX', 'Seven months of physical therapy, medication management, and two injections produced persistent functional limitation.'),
    ('DOC-3003-SPINE', 'Right ankle dorsiflexion is 4/5.'),
    ('DOC-3003-NEURO', 'Bilateral ankle dorsiflexion is 5/5 without focal weakness.'),
    ('DOC-3003-SPINE', 'Planned posterolateral fusion at L4-L5.'),
    ('DOC-3004-RHEUM', 'Seropositive rheumatoid arthritis remains moderately active.'),
    ('DOC-3004-RHEUM', 'Methotrexate was used for four months at a therapeutic dose with inadequate response.'),
    ('DOC-3004-LABS', 'Blood counts and hepatic-function values are within the documented treatment parameters.'),
    ('DOC-3005-SLEEP', 'Apnea-hypopnea index is 22 events per hour, consistent with moderate obstructive sleep apnea.'),
    ('DOC-3005-NOTE', 'Patient reports excessive daytime sleepiness and witnessed apneas.'),
    ('DOC-3005-ORDER', 'Auto-adjusting CPAP prescribed at 6–14 cm H2O with humidification and mask supplies.')
  ) as expected(document_id, quote_text)
  join public.clearway_documents d on d.document_id = expected.document_id
  where position(expected.quote_text in d.document_text) = 0;

  if quote_failure_count <> 0 then
    raise exception '% displayed evidence quotes are absent from their source documents', quote_failure_count;
  end if;

  if exists (
    select 1
    from public.clearway_policy_criteria pc
    join public.clearway_policy_versions pv on pv.policy_version_id = pc.policy_version_id
    where position(pc.policy_quote in pv.policy_text) = 0
  ) then
    raise exception 'A policy criterion quote is absent from the pinned full policy text';
  end if;

  if (select count(*) from public.clearway_ai_case_inputs) <> 5 then
    raise exception 'Expected five AI case-input bundles';
  end if;
  end if;
end
$verify$;

commit;
