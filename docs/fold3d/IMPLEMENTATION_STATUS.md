# Fold3D implementation record and approval blocker

## Related design roadmap and later operational note

The [architecture and power-recovery roadmap](ARCHITECTURE_AND_POWER_ROADMAP.md), documented 2026-09-12, expands the planned source changes, physical artifact contracts, tests, fairness policy, and extension gates E01–E04. It is a design proposal, not a new implementation result.

After the approval-blocker record below, a read-only GPL source transfer was resubmitted, explicitly approved by the runtime, and completed with exit code 0. A subsequent read-only workspace check succeeded. This resolved that particular operation, not all future approvals, and did not advance native integration or physical PPA. The approval section below is retained as historical diagnosis.

## Scope and publication status

This is a documentation-only checkpoint on the native Fold3D development branch. It does not claim that the standalone kernel or local Python prototypes have been committed. The intended deliverable remains a native joint XY/tier GPL optimizer, physically validated two-tier backend, and controlled power experiments. No native-3D power benefit has been measured.

## Change inventory

| Artifact/change | Location/status | Verified evidence | Not established |
|---|---|---|---|
| F01-F30 requirement checklist | `docs/fold3d/CHECKLIST.md`, already published | Existing branch checklist | Completed implementation of requirements |
| Detailed F01-F30 test matrix | VM checkout `docs/fold3d/TEST_PLAN.md`, untracked | 30 rows independently counted | All planned tests executable |
| Tier-membership kernel | VM checkout `src/gpl/src/fold3dKernel.h`, untracked | Sigmoid memberships, tier area contributions and analytic derivatives tested | Spatial dual density or Nesterov integration |
| Standalone C++ suite | VM checkout `src/gpl/test/fold3d/`, untracked | Five groups, 915 checks, zero failures in parent reruns | Full objective gradients, derivative-overflow branch coverage, build-system registration |
| Unchanged baseline build | Separate isolated upstream-based checkout | Make build exit 0, `[100%] Built target openroad`; executable invoked | Modified Fold3D build |
| Existing GPL baseline regressions | Separate baseline build | 74/74 pass, exit 0; saved CTest log | Feature-disabled equivalence after integration |
| Backend prototype | Local staging directory only | Parent reran 3 Python tests successfully | OpenDB import/export, actual STA, physical routing/extraction |
| Benchmark prototype | Local staging directory only | Parent reran 7 Python tests successfully | AES/Ibex physical campaigns or measured PPA |
| Native GPL/Nesterov integration | Not delivered | Read-only interface discovery only | Actual joint XY/tier updates |

No manual benchmark cell/net/DEF moves were made. Existing shared experiment data was left untouched. No proprietary technology collateral, credentials, IP addresses, waveforms, or checkpoint weights are included in this documentation checkpoint.

## Standalone numerical evidence

Command in the VM development checkout:

```sh
bash src/gpl/test/fold3d/run.sh
```

Observed output:

```text
PASS conservation
PASS derivatives
PASS symmetry
PASS boundaries
PASS invalid
tests=5 failed=0 checks=915
```

The saved numerical RED log showed four failing groups against the incomplete implementation. The missing-header failure is separate structural evidence, not a numerical RED result. GREEN establishes tier-total area conservation and local derivatives, not area deposition into XY bins or full placement-energy gradients.

## Unchanged baseline build and regressions

The isolated baseline was based on branch commit `6bf2d2cd7492f309473300d5e9b9b97e972211d3`, which added documentation to the upstream-based source. Recursive submodules were initialized in that separate checkout.

Build environment: existing `openroad/ubuntu22.04-dev:69b3f8` container, CMake 3.31.9, GCC 11.4. The standalone numerical suite separately ran with host GCC 10.2.1.

The first configuration attempt selected Ninja, which was absent. The Make retry used a fresh directory and preserved the failed log:

```sh
cmake -S . -B build-fold3d-baseline-make -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=Release -DENABLE_TESTS=ON -DBUILD_GUI=OFF
cmake --build build-fold3d-baseline-make -j 8
ctest --test-dir build-fold3d-baseline-make -R '^gpl[.]' \
  --output-on-failure -j 4 --timeout 300
```

Observed final CTest summary:

```text
100% tests passed, 0 tests failed out of 74
Total Test time (real) = 14.92 sec
```

Existing VM evidence paths relative to the workspace parent:

- `baseline-evidence/build.log`: initial Ninja attempt.
- `baseline-evidence/build-make.log`: successful Make build, including warnings.
- `baseline-evidence/gpl-ctest.log`: GPL regression results.

The actual executable is `build-fold3d-baseline-make/bin/openroad`, not `src/openroad`. The latter was mistakenly supplied to a worker and corrected. Its version output was `HEAD-HASH-NOTFOUND` because the container mount did not expose all worktree Git metadata. This provenance defect remains open. Third-party ABC compilation and bzip2 linker warnings were recorded; successful compilation does not resolve those warnings.

## Local-only backend and benchmark tests

The parent independently executed Python unittest discovery against the local staging directories. Backend: 3 tests passed. Benchmark: 7 tests passed.

Backend coverage includes graph roundtrip with a shared cross-tier bond, corrupt connectivity/RC rejection, and wrong-tier/extra-bond rejection. This is a JSON structural prototype, not a qualified physical backend.

Benchmark coverage includes absent-backend blocking, fairness mismatches, missing fields/duplicate modes/unlabeled rows, missing/failed evidence, invalid power numbers and overlapping categories, and suppression of PPA from unit-only validation. Synthetic unit-test fixtures are not experimental results. These passing tests do not prove adversarial completeness or externally authenticated physical evidence.

Neither local prototype has been verified as uploaded into the VM checkout. No real timing or power reports were produced by these prototypes.

## Runtime approval gate: root cause and supported recovery

The workers reported:

```text
status: pending_approval
approval_pending: true
pattern_key: tirith:raw_ip_url
Security scan: URL points to an IP address instead of a domain name
```

This is a local Hermes tool-authorization gate. It is distinct from GCP OAuth, SSH authentication/network connectivity, VM billing consent, OpenROAD compilation, and physical-design acceptance gates. Read-only SSH/build operations succeeding does not approve every separately scanned file-transfer/write command.

The current official Hermes gateway documentation specifies:

- `/approve`: approve and execute a pending command.
- `/approve session`: session-scoped approval.
- `/approve always`: permanent allowlisting; not recommended for this broad scanner pattern without examining its scope.
- `/deny`: reject a pending command.

An ordinary message such as “I approve it” communicates user intent but is not a substitute for processing the runtime approval entry. Prior retries mistakenly assumed otherwise. The approval must correspond to the actual pending command and intended checkout. If no pending entry exists after a worker has exited, the original operation must be presented again through the normal approval mechanism. If a child approval is not visible in the originating gateway conversation, investigate approval routing rather than repeatedly redispatching or assuming it is approved.

No security configuration was disabled, permanent allowlist added, destination disguised, or blocked transfer retried through another mechanism for this checkpoint. Publishing this documentation to GitHub is separate from authorizing remote implementation writes.

Official reference: https://hermes-agent.nousresearch.com/docs/reference/slash-commands/

## Remaining acceptance sequence

1. For further implementation writes, obtain any required command-specific approval and inspect current partial-write state. The later read-only transfer was approved; do not assume blanket approval.
2. Review and publish the existing standalone source/tests and detailed matrix as a coherent snapshot; currently untracked/unpublished.
3. Add executable behavioral tests before each actual GPL integration change; register tests in CMake and Bazel. Verify unchanged default 2D behavior against the baseline.
4. Complete dual spatial density, gradient sweeps, capacity migration, stable joint XY/tier updates, annealing and rounding/legalization. A standalone tier update is not a complete native optimizer.
5. Validate tier materialization, shared-bond topology, explicit RC accounting, connectivity, clock paths and combined STA on a real tiny fixture, then actual routing/extraction.
6. Run fixed-RTL AES first, then Ibex, with predeclared seeds and 2D/frozen-tier/joint-tier controls.
7. Compare total power at matched workload/ROI, voltage, frequency, throughput, corners and constraints. Include clock/vertical contributions without double counting; distinguish projected footprint from total active silicon area.
8. Require physical/timing validity before interpreting a gain; publish failures, negative outcomes, sensitivity and limits. Perf/W is separate from matched-frequency absolute power. No percentage improvement is assumed.
