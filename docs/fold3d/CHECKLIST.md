# Fold3D implementation and verification checklist

Status: native integration and physical benchmarks pending. Partial baseline/kernel/prototype evidence is recorded in [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md); it does not complete the integrated requirements below.

See [ARCHITECTURE_AND_POWER_ROADMAP.md](ARCHITECTURE_AND_POWER_ROADMAP.md) for the complete source integration design, artifact contracts, benchmark policy, and additional power-recovery gates E01–E04.

Upstream baseline: `41a28926b92c5c20f41f89e90222a95a820384d2`.
Target: existing worker-1, isolated workspace. The earlier GCP access blocker was resolved; a later source transfer received runtime approval and completed. Individual command approvals and physical acceptance remain separate gates.

A checkbox is completed only with code and passing test/log evidence. Keep the evidence table current after each increment.

- [ ] F01 **Infrastructure** — Verify worker-1 identity, free disk, memory, active jobs and tool inventory; use an isolated owned workspace; preserve all GF data.
- [ ] F02 **Pinned build** — Record upstream SHA and dependencies; build unmodified OpenROAD and run GPL regressions before editing.
- [ ] F03 **Baseline equivalence** — Feature-disabled mode preserves vanilla placement behavior and regression outputs.
- [ ] F04 **GPL state** — Keep experimental state GPL-side; no OpenDB schema changes; distinguish movable instances, fixed objects and fillers.
- [ ] F05 **Joint updates** — Update XY and relaxed tier variables within the same Nesterov loop; no frozen initial partition.
- [ ] F06 **Relaxation study** — Compare sigmoid logits with bounded tier variables; test saturation, symmetry breaking and seed sensitivity.
- [ ] F07 **Annealing** — Implement temperature/binarization schedules with consistent step-size estimation and convergence monitoring.
- [ ] F08 **Dual density** — Independent tier capacity, blockages, available area, fillers and cell-footprint deposition; conserve total cell area.
- [ ] F09 **Gradient consistency** — Finite-difference checks for XY/tier derivatives against the actual reported objective, including density energy.
- [ ] F10 **Density migration** — Asymmetric-capacity test migrates cells appropriately without manual assignment.
- [ ] F11 **3D wirelength** — Smoothed XY/vertical net cost; positive vertical cost discourages crossing unless lateral/capacity benefits outweigh it.
- [ ] F12 **Core proof** — Capacity-constrained synthetic test with independently checked folded advantage; converse vertical-cost sensitivity test.
- [ ] F13 **Electrical model** — Explicit units and calibrated bond/access R,C assumptions; optimistic/nominal/pessimistic sensitivity, no literal distance-as-delay claim.
- [ ] F14 **Timing** — Criticality weighting uses consistent cross-tier cost; controlled test demonstrates timing can alter tier decisions.
- [ ] F15 **Activity** — Validated workload activity and capacitance proxy; controlled test demonstrates activity can alter decisions; no signoff-power claim.
- [ ] F16 **Bond topology** — Define multi-pin net vertical-connection topology and avoid equating pairwise crossing sums with physical bond count.
- [ ] F17 **Bond location** — Generate candidate landing locations, deposit soft demand, enforce capacity and assign legal sites after rounding.
- [ ] F18 **Rounding** — Report relaxed, rounded and legalized capacity separately; handle residual fractional cells without hiding violations.
- [ ] F19 **Materialization** — Export tier netlists/DEF and vertical connectivity manifest preserving logical identity and intended XY; validate roundtrip connectivity.
- [ ] F20 **Backend fixture** — Early tiny two-tier fixture validates terminal models, landing access, legalization, routing and extraction independently of optimizer.
- [ ] F21 **Clock and STA** — Explicit clock/vertical skew assumptions and combined cross-tier paths; correct SPEF/bond RC stitching without double counting.
- [ ] F22 **AES** — AES with public Nangate45 collateral, multiple seeds and iteration traces; no manual cell/net/DEF optimization.
- [ ] F23 **Ablations** — 2D baseline, frozen-tier XY, joint XY/tier, timing, activity, bond constraint; control seeds and physical resources.
- [ ] F24 **Fairness** — Same logic/corners/constraints/workload; report projected footprint AND total active silicon, legality, DRC, connectivity and timing limits.
- [ ] F25 **Ibex** — Secondary benchmark after AES passes; ASAP7 stretch only, GCD for smoke only.
- [ ] F26 **Metrics** — Separate placement proxies from routed Fmax/power/perf-W; publish unfavorable results and bond sensitivity; no assumed 40% gain.
- [ ] F27 **Observability** — Log objective components, tier changes, fractional assignments, overflow and convergence; excessive tier switching is not success.
- [ ] F28 **Scope** — No new 3D router, CTS engine, thermal/PDN solver or heterogeneous tier support; integration requirements remain mandatory.
- [ ] F29 **Reproducibility** — CLI help, runnable scripts, pinned inputs, tests, sanitized logs and measured evidence; no proprietary collateral or credentials.
- [ ] F30 **Source verification** — Verify actual GPL source/API structure and upstream paper claims before relying on named files or reported gains.

## Evidence ledger

| Requirement | Implementation | Test / command | Observed result | Limitations |
|---|---|---|---|---|
| F01–F02 | Partial baseline evidence | Baseline build and GPL CTest; see implementation record | Build exit 0; 74/74 regressions passed | Provenance defect remains; no modified-build equivalence |
| F06, F08–F09 | Standalone tier math only | `bash src/gpl/test/fold3d/run.sh` in development checkout | 5 groups / 915 checks passed | No spatial deposition or full-objective gradients; source/tests not published in this snapshot |
| F19–F21 | Local structural backend prototype | Previously rerun Python tests | 3 tests passed | No actual materialization/routing/extraction/STA qualification |
| F24, F26, F29 | Local benchmark validator prototype | Previously rerun Python tests | 7 tests passed | No physical campaign or PPA result |
| Other integrated requirements | Pending | Not qualified | No completion claim | See roadmap and implementation record |

## Additional power-recovery gates

These extension gates do not renumber or mark complete F01–F30. Details and acceptance tests are in the [roadmap](ARCHITECTURE_AND_POWER_ROADMAP.md).

- [ ] E01 **Electrical reoptimization** — Inspect resizer/timing APIs and implement controlled downsizing, buffering/removal, and timing repair using the folded electrical model.
- [ ] E02 **Equivalence and fairness** — Separate fixed-mapped-netlist placement tests from same-RTL/common-input recovery tests; require equivalent logic and matched optimization policy, not identical final netlist hashes.
- [ ] E03 **Post-edit revalidation** — Refresh physical implementation/parasitics and require connectivity, equivalence, setup/hold, electrical limits, and fresh power evidence after edits; reject stale reports.
- [ ] E04 **Bounded feedback** — Automated physical-feedback revisions with declared resource/iteration limits, acceptance, rollback, reproducibility, and no manual benchmark-specific moves.

## Delivery order

1. VM/build baseline.
2. Numerical kernel and gradient tests, alongside backend fixture.
3. Integrated GPL joint placement and rounded capacity.
4. Materialization, bond legality and combined timing.
5. AES, ablations, Ibex and physically qualified metrics.

No unrelated TinyRocket/Therm-FM or local Docker rollout work is included in this branch.
