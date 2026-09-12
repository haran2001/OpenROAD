# Fold3D architecture and power-recovery roadmap

Documented: 2026-09-12. Documentation-only design proposal, not an implementation or benchmark result.

Repository: `haran2001/OpenROAD`; branch: `fold3d/native-kernel-20260911-182803`.
Documentation base inspected: `2e0c9d8`. Upstream source baseline: `41a28926b92c5c20f41f89e90222a95a820384d2`.

Related records:
- [Implementation and verification checklist](CHECKLIST.md)
- [Implementation evidence and operational history](IMPLEMENTATION_STATUS.md)

## 1. Objective and evidence boundary

Extend OpenROAD from optimizing positions in a plane to jointly optimizing lateral positions and assignment to two tiers. Then use the resulting electrical improvements to recover power without sacrificing required performance.

Putting a design on two tiers is not enough. The flow must shorten electrically important connections, pay the real cost of vertical connections, and allow physical optimization to recover capacitance, buffering, and drive-strength savings.

The implementation has three principal parts:
1. Native joint XY/tier placement inside GPL.
2. A physically valid two-tier implementation and timing/electrical backend.
3. A controlled benchmark pipeline measuring total power and performance, not only placement proxies.

The original F01–F30 checklist is stronger on placement than on cell/buffer power recovery. This document explicitly adds controlled post-fold electrical optimization and bounded physical feedback as extension gates E01–E04. These are proposed work, not completed functionality.

### Huawei-style North Star: not a reproduction claim

Earlier project discussion used a reported roughly 41% energy-efficiency improvement from Huawei-style logic folding as a North Star. That figure is historical discussion context; it has not been independently source-qualified or reproduced here. No primary-source citation establishing its exact metric and experimental conditions is available in this record. Do not cite this roadmap as evidence of Huawei's measured result.

Before claiming reproduction, establish the design, technology, workload, voltage, frequency, throughput, bonding assumptions, and measurement methodology from primary sources. Our public-design experiment does not presently establish that equivalence.

Higher performance per watt is not the same percentage as lower power. For efficiency defined as throughput/power, 41% higher efficiency at identical throughput would imply a power ratio of `1 / 1.41`, or approximately 29.1% lower power. This is an illustrative conversion, not an experimental result. Frequency, voltage, or architectural changes can change the interpretation.

The acceptance objective is reproducible improvement under controlled assumptions. A headline percentage is not an acceptance criterion, reward target, or assumed outcome.

## 2. Physical mechanism and trade-offs

```text
Planar connection:
Driver -------- long lateral wire / possible buffers -------- Receiver

Potentially useful folding:
Top tier                         Receiver
                                    |
                             bond + access wiring
                                    |
Bottom tier                      Driver
```

The new connection cost includes bottom access wiring, bond resistance/capacitance, top access wiring, and remaining lateral routing. Vertical connections are not free.

Possible benefits:
- Lower switched wire capacitance and interconnect delay.
- Fewer buffers and smaller drivers where timing permits.
- Lower cell area and potentially lower leakage.

Possible penalties:
- Bond and landing-access parasitics.
- Clock distribution cost and skew.
- Congestion near bond sites and legalization displacement.
- Hold fixes or additional buffering.
- Temperature-dependent leakage.

The optimizer must discover when folding is useful and retain same-tier connections when they are better. Shorter estimated wirelength alone does not prove lower total power.

## 3. End-to-end architecture

```text
Fixed RTL / common mapped input
Libraries + constraints + activity + tier technology assumptions
                              |
                              v
                    Unified logical design
                              |
                              v
                  Native Fold3D inside GPL
       +------------------------------------------------+
       | Joint XY/tier state and optimizer history       |
       | Independent density fields per tier            |
       | Lateral/vertical objective and derivatives     |
       | Timing/activity weights and bond demand        |
       +------------------------------------------------+
                              |
                              v
                    Round and legalize tiers
                              |
                              v
                 Materialize physical artifacts
          Tier netlists/DEF + identity/bond manifest
                              |
                              v
             Placement / CTS / routing / extraction
                              |
                              v
                   Combined timing and power
                              |
                              v
          Controlled resizing / buffering recovery
               and refreshed physical validation
                              |
                              v
                    Matched comparison report
```

The first implementation does not introduce a new 3D router, CTS engine, thermal/PDN solver, heterogeneous-tier flow, or OpenDB schema. Integration with existing capabilities is still mandatory; those scope limits do not waive physical validation.

## 4. OpenROAD source integration map

Source orientation in the inspected branch identifies:

| Existing area | Planned responsibility |
|---|---|
| `src/gpl/src/nesterovPlace.cpp`, `.h` | Joint iteration orchestration, acceptance, annealing, convergence |
| `src/gpl/src/nesterovBase.cpp`, `.h` | Cell/optimizer state, tier density and gradients |
| `src/gpl/src/placerBase.cpp`, `.h` | Logical/placement mapping and lifecycle integration as needed |
| `src/gpl/src/replace.cpp` | Feature/options plumbing and initialization |
| `src/gpl/src/replace.tcl`, `replace.i`, `replace-py.i` | Documented controls and bindings; no invented CLI flags |
| `src/gpl/src/timingBase.cpp`, `.h` | Consistent timing-driven feedback |
| Density/wirelength gradient backends | Objective/derivative integration; explicit backend support |
| `src/gpl/test/fold3d/` | Numerical and integrated tests, registered in supported build systems |
| `tools/fold3d_backend/` | Proposed physical materialization and validation tooling |
| `tools/fold3d_bench/` | Proposed campaign, fairness and evidence validation tooling |
| Existing resizer/timing interfaces | Power-recovery extension, exact sufficient API sequence unverified |

The existing loop includes `NesterovPlace::doNesterovPlace()` and `updateNextIter()`. Adding a tier update there is necessary but insufficient: objective, derivatives, preconditioning, optimizer history, and step acceptance must agree. Source orientation is not verification that these changes are implemented.

Proposed module locations are not claims that those modules already exist. Do not silently let an alternate acceleration backend bypass Fold3D semantics: implement parity or reject an unsupported configuration explicitly.

### 4.1 Tier state without an initial OpenDB schema change — F03–F04

Maintain GPL-side state associated with stable logical instance identities:
- XY coordinates and optimizer history.
- Relaxed tier variable, derivative, preconditioner, and history.
- Movable/fixed/filler classification and allowed-tier constraints.
- Final discrete assignment.

Do not rely only on mutable vector indices. Physical optimization can insert, remove, or resize instances; the state mapping must survive those changes or be explicitly rebuilt.

Acceptance tests: default 2D equivalence; fixed objects cannot migrate; fillers are not logical cells; deterministic initialization/reset; correct state after instance lifecycle changes.

### 4.2 Joint XY/tier Nesterov optimization — F05–F07

Avoid choosing a partition once and freezing it. Evaluate a joint objective, compute XY and tier derivatives, propose coordinated updates, check numerical validity/step acceptance, and update history together.

Compare sigmoid/logit relaxation with bounded tier variables. Test saturation, symmetry breaking, and seed sensitivity. Temperature/binarization schedules should encourage discrete assignments without silently invalidating the step-size or momentum model.

XY coordinates and tier variables have different scales. Reusing the XY step size uncritically may cause divergence or ineffective tier movement.

Acceptance tests: actual loop changes tier decisions in response to capacity/connectivity; no NaNs; stable schedule transitions; controlled seed behavior; feature-disabled regression equivalence. A logged changing tier variable is not sufficient proof of useful placement.

### 4.3 Independent spatial density per tier — F08–F10

```text
Bottom grid                       Top grid
-----------                       --------
Bottom capacity                   Top capacity
Bottom fixed objects/blockages    Top fixed objects/blockages
Bottom filler policy              Top filler policy
Bottom overflow                   Top overflow
```

The standalone kernel conserves area between tiers; it does not yet deposit footprints into spatial bins. Implement weighted footprint deposition, not just center assignment. Preserve total area across bins and tiers, respect boundaries and available capacities, and derive XY and tier forces from the reported density energy.

Acceptance tests: global/bin conservation; boundary cases; fixed-object/blockage accounting; asymmetric-capacity migration; finite differences for density-energy derivatives. A relaxed mathematical solution must not conceal an impossible physical placement.

### 4.4 3D objective and consistent derivatives — F09, F11–F13

Conceptually:

```text
Objective = lateral connection cost
          + vertical connection cost
          + independent density penalties
          + bond-demand penalty
          + binarization term
```

Document units or normalization and the role of timing/activity weights. A positive vertical penalty discourages crossings; it does not create useful folding by itself. Lateral/electrical or capacity benefits must outweigh that penalty.

Acceptance tests: an independently checked, capacity-constrained folded-advantage example; a converse vertical-cost sweep; full-objective XY/tier finite differences; identical model in reported energy and analytic derivatives. Distance must not be reported as electrical delay.

### 4.5 Timing and activity awareness — F14–F15

Use criticality, validated switching activity, capacitance estimates, and explicit cross-tier electrical cost. Reuse existing timing-driven infrastructure where suitable, but represent complete cross-tier paths rather than unrelated tier timing problems.

Activity must map correctly to nets/instances and the workload interval. Missing activity requires explicit coverage reporting, not hidden defaults presented as measured workload power.

Acceptance tests: criticality alters a controlled tier choice; activity alters a controlled power-oriented choice; missing coverage is rejected or prominently qualified; placement proxies never become signoff-power claims.

### 4.6 Bond topology, locations, and capacity — F16–F17

```text
Bottom driver -- one shared bond -- top routing tree -- several sinks
```

Pairwise crossings need not equal physical bond count. Define multi-pin topology, candidate landing locations, spatial soft demand, capacity/keepouts, legal post-rounding assignment, and access parasitics.

Acceptance tests: preserve all shared-bond sinks; reject merged nets, missing drivers, overbooked sites, wrong-tier terminals, and duplicate RC; reject inaccessible landing sites. Existing structural JSON tests do not qualify physical landing legality.

### 4.7 Rounding and legalization — F18

Automate discrete assignment and repair under tier capacity, legality, bond demand, and incremental objective/timing cost. No manual cell/net/DEF moves to rescue individual benchmarks.

Report relaxed, rounded, and legalized solutions separately: overflow, displacement, bond changes, timing/proxy degradation, and remaining violations. A good relaxed objective is not evidence of a feasible final placement.

## 5. Physical backend and artifact contracts — F19–F21

Inputs: original logical netlist, stable identities, tier/XY assignments, public technology/library data, bond topology/sites, constraints, clock assumptions.

Outputs: tier netlists/DEFs; logical-to-physical identity mapping; vertical-connectivity manifest; extracted/stitched parasitic artifacts with provenance; combined timing, power, and physical-validity reports.

### Connectivity

Preserve the original circuit during splitting. Reject dropped sinks, duplicated/missing drivers, merged nets, absent vertical connections, and wrong-tier terminals. Validate export/import roundtrip rather than only validating internal JSON.

### Timing/electrical path

```text
Driver cell -> bottom wiring -> access/bond RC -> top wiring -> receiver
```

Include complete clock paths, skew, setup, hold, and explicit RC units. Prevent double counting across extracted and explicitly attached parasitics. Two isolated STA runs are insufficient.

### Tiny physical fixture before AES

Qualify materialization, terminal models, legal landing access, legalization, routing, extraction, and combined STA on a tiny fixture independently of optimizer quality. Missing tools, skipped stages, or placeholder reports leave this gate incomplete.

## 6. Power recovery: extension beyond placement

### E01 — Controlled electrical reoptimization

Shorter wires may reduce net switching power, but excess buffers or oversized drivers can remain. Use the resulting electrical model to propose downsizing, buffer removal, rebuffering, and timing repair.

Inspect existing resizer/timing APIs first. Add narrow source changes only when tests demonstrate an interface gap. The exact sufficient command/API sequence has not yet been verified. Record each edit's reason and outcome; do not imply an untested command sequence is operational.

### E02 — Equivalent and fair optimization contracts

Use two experiments:
1. **Fixed mapped netlist:** isolate placement/interconnect effects.
2. **Same RTL/common starting netlist with matched optimization policy:** evaluate placement plus resizing/buffering recovery.

Final netlist hashes can change legitimately in the second experiment. Require input lineage, functional equivalence, edit audit, and matched policy/budgets, not an identical final-netlist hash. Both 2D and 3D controls must have equivalent recovery opportunities.

Tests: reject changed logic or missing lineage; accept equivalent permitted physical edits; reject asymmetric optimization policy. Track buffer counts, drive-strength distribution, cell area, leakage, and total power.

### E03 — Refresh physical/electrical evidence after edits

After changes, refresh legalization/routing as required, parasitics, connectivity/equivalence, setup/hold, electrical limits, and power. A pre-edit report cannot qualify a post-edit candidate. Reject stale evidence and any candidate failing the physical or timing gates.

### E04 — Bounded physical-feedback loop

```text
Place -> materialize -> route/extract -> analyze
  ^                                        |
  +------ controlled algorithmic revision --+
```

Later feed routing/timing outcomes into automated candidate generation. Bound iterations and resources, retain rollback candidates, and predeclare acceptance rules. No manual benchmark-specific moves, no claims of unrestricted native 3D route optimization. Tests must cover stopping, rejection/rollback, reproducibility, and unchanged-input reuse without stale evidence.

## 7. Benchmark campaign and acceptance — F22–F26, F29

Use AES with public Nangate45 collateral first, then Ibex. Synthetic circuits support numerical/integration proofs; GCD is smoke only and ASAP7 is stretch scope.

| Variant | Question |
|---|---|
| 2D baseline | What does the ordinary flow achieve? |
| Frozen-tier 3D | What does a fixed partition achieve? |
| Joint XY/tier | Does dynamic tier optimization add value? |
| Timing-aware joint | Does timing feedback help? |
| Activity-aware joint | Does workload awareness help? |
| Bond-constrained joint | Does benefit survive real resource constraints? |
| Matched post-placement recovery | Does resizing/buffering produce a fair additional benefit? |

Predeclare seeds, physical resources, optimization budgets, constraints, corners, workload/ROI, voltage, frequency, and throughput. Match total active silicon and report projected footprint separately. Do not gain an undeclared resource advantage from extra metal or capacity.

Hard gates before interpreting power:
- Connectivity and required functional equivalence.
- Placement legality, routing, and declared DRC acceptance.
- Setup/hold and electrical limits.
- Sufficient activity coverage.
- Bond/access RC and complete clock accounting.
- No overlapping power categories.
- Matched conditions and fresh, traceable physical evidence.

Report total/dynamic/leakage power, clock attribution without double counting, WNS/TNS and hold, throughput/energy per operation, wirelength/extracted capacitance, buffer and drive-strength distribution, bond usage, projected footprint/total silicon area, runtime, failures, and sensitivity to parasitics/capacity. Placement proxies and synthetic unit fixtures must remain labeled.

Temperature-dependent leakage is a limitation unless a consistent temperature model is established; not building a thermal solver does not justify ignoring the assumption. Publish negative outcomes and failures, not only selected favorable seeds. Fmax/perf-W sweeps are separate from matched-frequency absolute power comparisons.

## 8. Observability, reproducibility, and scope — F27–F30

Log objective components, XY/tier gradients, accepted steps, schedules, tier changes, fractional assignments, per-tier overflow, bond demand, and convergence. Excessive tier switching is not success.

Publish runnable scripts, CLI help, pinned inputs/tool versions, hashes, test commands, sanitized logs, metrics, limitations, and evidence provenance. Keep reusable code in repository tool/script directories, not dated narrative folders. Do not publish credentials, host access details, proprietary collateral, private meeting material, or unapproved activity traces.

Verify actual source APIs and primary paper claims before relying on them. Runtime command approval, build success, unit-test success, and physical acceptance are distinct gates. This roadmap does not grant broad runtime approval or launch experiments.

## 9. Delivery order and RED/GREEN acceptance

| Stage | Work | Required evidence |
|---|---|---|
| Foundation | Pinned baseline, isolation, kernel | Build/regressions and numerical tests |
| Native core | State, dual density, full objective, joint updates | Behavioral tests, gradients, controlled folded advantage |
| Early backend (parallel) | Tiny connected two-tier fixture | Actual physical/timing evidence |
| Physical handoff | Rounding, legal bonds, export | Legal connectivity-preserving implementation |
| First experiment | AES controls/ablations | Matched physically qualified PPA |
| Power recovery | E01–E03 | Equivalence, refreshed parasitics, timing-valid total power |
| Generalization | Ibex and sensitivities; bounded E04 | Reproducible benefit or documented limitations |

For each change, write executable acceptance tests first, demonstrate the meaningful RED failure, implement, and preserve GREEN evidence. Missing-header failures are structural, not substitutes for numerical RED. Register tests in supported build systems, rerun relevant regressions, and verify publication. Skips/missing fixtures remain incomplete gates.

## 10. Recorded implementation status at this documentation checkpoint

The following are prior independently executed results recorded in [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md); this documentation update does not rerun or expand them:
- Unchanged baseline build succeeded; 74/74 GPL regressions passed.
- Standalone numerical kernel: five groups, 915 checks, zero failures.
- Local backend structural prototype: three tests passed.
- Local benchmark validation prototype: seven tests passed.

Not delivered: native joint GPL/Nesterov implementation; spatial dual density; qualified physical/combined-timing backend; integrated post-fold power recovery; real AES/Ibex PPA comparison.

Existing kernel/tests/test matrix remain unpublished in the recorded implementation snapshot; local prototypes are not established as uploaded. A later approved read-only GPL source transfer completed, but it neither changed production code nor granted blanket approval for remote writes.

## Bottom line

```text
Joint placement
  -> physically useful folding
  -> lower actual interconnect cost
  -> recovered cell/buffer power
  -> validated whole-design timing and power
```

The placement checklist establishes the foundation. Controlled electrical reoptimization and renewed physical validation are needed to test the larger power opportunity. No percentage improvement is guaranteed or measured by this document.
