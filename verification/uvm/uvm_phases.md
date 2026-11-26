# UVM Phases — Interview Preparation

This guide explains the UVM phasing mechanism, the standard phases, phase ordering, objections, and practical coding patterns. Examples use the UVM 1.2-style API; the core concepts are also applicable to IEEE 1800.2 UVM implementations. Some details and available APIs can vary slightly by implementation/version.

## 1. What is a UVM phase?

A **UVM phase** is a standard lifecycle callback that coordinates what testbench components do and when they do it. Phases provide a predictable order for constructing the environment, connecting its components, running stimulus, checking results, and cleaning up.

A `uvm_component` can implement phase methods such as `build_phase`, `connect_phase`, and `run_phase`. The UVM phasing engine calls those methods; normally, the test writer does **not** call them directly.

### Why phases are useful

- They give every component a common lifecycle.
- They make reusable agents and environments easier to compose.
- They separate setup, execution, checking, and reporting responsibilities.
- They coordinate concurrent components without hard-coding calls between them.

## 2. Phase categories

The standard component phases are commonly grouped as follows:

| Category | Purpose | Examples |
|---|---|---|
| Build-time (function) phases | Construct and configure the component hierarchy | `build_phase`, `connect_phase` |
| Elaboration (function) phases | Finalize and inspect the completed hierarchy before simulation | `end_of_elaboration_phase`, `start_of_simulation_phase` |
| Runtime (task) phases | Execute stimulus and time-consuming behavior | `run_phase`, `main_phase`, `reset_phase` |
| Cleanup/report (function) phases | Extract data, check outcomes, report, and clean up | `extract_phase`, `check_phase`, `report_phase`, `final_phase` |

A **function phase** must complete without consuming simulation time. A **task phase** may wait, delay, or execute time-consuming work. Do not put `#delay`, `@event`, or other time-consuming behavior in a function phase.

## 3. Standard component phase sequence

The usual top-level lifecycle is:

```text
build_phase
connect_phase
end_of_elaboration_phase
start_of_simulation_phase
run-time phase schedule (including run_phase)
extract_phase
check_phase
report_phase
final_phase

UVM report summary (printed by the UVM reporting infrastructure)
```

The runtime schedule itself has a sequence of runtime phases described below. The exact schedule can be customized, but standard UVM testbenches should generally use the standard schedule unless there is a specific reason not to.

### Traversal and execution

- `build_phase` traverses the component hierarchy **top-down**. A parent can create children before those children build themselves.
- `connect_phase` traverses **bottom-up** so components can connect ports and exports after construction.
- Other function phases have defined UVM traversal behavior; do not rely on arbitrary ordering between unrelated components. Keep phase callbacks focused on their documented responsibility.
- Runtime task phases execute concurrently across the component hierarchy. Components should coordinate through TLM connections, sequencers, events, and objections—not by assuming another component's task happens first.
- The UVM phase engine automatically invokes a component's phase callback when that component participates in that phase.

## 4. Build and elaboration phases

### `build_phase(uvm_phase phase)`

Create child components and retrieve configuration. This is the main place to construct the environment hierarchy. It is a function phase and must not consume time.

```systemverilog
function void build_phase(uvm_phase phase);
  super.build_phase(phase);

  agent = my_agent::type_id::create("agent", this);
  if (!uvm_config_db#(virtual bus_if)::get(this, "", "vif", vif))
    `uvm_fatal("NOVIF", "Virtual interface 'vif' was not configured")
endfunction
```

Call `super.build_phase(phase)` in an override so inherited component behavior is preserved. Use the factory `type_id::create` for factory-controlled components rather than `new`.

### `connect_phase(uvm_phase phase)`

Connect already-created TLM ports, exports, and analysis connections. It is a function phase; create components in `build_phase`, not here.

```systemverilog
function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  agent.monitor.ap.connect(scoreboard.analysis_export);
endfunction
```

### `end_of_elaboration_phase(uvm_phase phase)`

Runs after construction and connection. Use it for final topology-dependent checks or diagnostics, such as printing the component topology. It is a function phase.

### `start_of_simulation_phase(uvm_phase phase)`

Runs immediately before runtime activity begins. Use it for final setup or informational messages that should occur after elaboration. It is a function phase; it is not the place for timed reset or stimulus.

## 5. Runtime phases

Runtime phases are task phases and can contain time-consuming behavior. The standard runtime schedule contains these phases:

| Runtime phase | Typical responsibility |
|---|---|
| `pre_reset_phase` | Prepare for reset, if the environment needs a distinct pre-reset step |
| `reset_phase` | Assert/apply reset and establish a known DUT state |
| `post_reset_phase` | Release reset and perform post-reset settling or checks |
| `pre_configure_phase` | Prepare for DUT configuration |
| `configure_phase` | Program DUT configuration registers or settings |
| `post_configure_phase` | Verify configuration completion or settling |
| `pre_main_phase` | Prepare for normal traffic |
| `main_phase` | Run the main test scenario or traffic |
| `post_main_phase` | Stop or drain normal traffic and perform end-of-test actions |
| `pre_shutdown_phase` | Prepare for shutdown |
| `shutdown_phase` | Complete outstanding work or drive the interface to an idle state |
| `post_shutdown_phase` | Final runtime cleanup before leaving the runtime schedule |

These named runtime phases are useful for separating responsibilities in larger environments. A small testbench may put its main stimulus in `run_phase` and use only a subset of the schedule.

### `run_phase(uvm_phase phase)`

`run_phase` is the most commonly used runtime callback. It is a task, so it may start sequences, wait for events, and consume simulation time. The UVM runtime phase schedule and `run_phase` are coordinated by the phasing system; do not assume that `run_phase` is a sequential wrapper around the named runtime phases.

```systemverilog
task run_phase(uvm_phase phase);
  phase.raise_objection(this, "test stimulus is active");

  // Start stimulus, wait for completion, or perform timed checks here.
  repeat (10) @(posedge vif.clk);

  phase.drop_objection(this, "test stimulus completed");
endtask
```

### Phase-specific callbacks

Components may implement callbacks such as `reset_phase`, `configure_phase`, and `main_phase` when their behavior should be separated by runtime responsibility. For example, a driver or virtual sequence can participate in reset and main traffic in distinct callbacks. Coordinate phase-specific work with the environment's sequencing strategy and objections.

```systemverilog
task reset_phase(uvm_phase phase);
  phase.raise_objection(this, "performing reset");
  drive_reset();
  wait_for_reset_release();
  phase.drop_objection(this, "reset completed");
endtask
```

The example assumes `drive_reset` and `wait_for_reset_release` are task methods available in the component. A reusable agent should normally drive protocol behavior through its sequencer/driver and configured virtual interface.

## 6. Objections: keeping runtime phases alive

An **objection** tells the phase engine that a component is not finished with a runtime phase. When all objections for the phase are dropped, the phase can end, subject to UVM phase scheduling and any configured drain time.

Typical pattern:

1. Raise an objection before beginning work that must keep the phase alive.
2. Perform stimulus or wait for the required completion condition.
3. Drop the objection when that work is complete.

```systemverilog
phase.raise_objection(this, "starting test traffic");
seq.start(env.agent.sequencer);
phase.drop_objection(this, "test traffic completed");
```

Important points:

- Objections are primarily used in task/runtime phases, not function phases.
- Every raised objection must eventually be dropped. A missing drop can make simulation hang.
- Do not drop an objection immediately after launching background work if that work still needs the phase to remain active.
- Prefer raising and dropping objections at the test or sequence orchestration level. Avoid every component independently holding an objection without a clear reason.
- `phase.raise_objection` and `phase.drop_objection` accept an object that identifies the source and an optional description.
- UVM can report objection activity; use UVM verbosity and objection tracing when diagnosing a phase that does not end.
- A drain time can allow in-flight activity to complete after objections are dropped, but it does not replace correct objection ownership and cleanup.

### Objection pitfall: sequence completion

A sequence does not automatically keep a phase alive merely because it was started in the background. The test should ensure the phase remains active until the sequence and any required checking are complete. One straightforward pattern is for the test to raise an objection, start the sequence, and then drop the objection after `start()` returns.

## 7. Cleanup and reporting phases

These are function phases, called after runtime execution has ended:

### `extract_phase(uvm_phase phase)`

Collect or derive final data from the testbench, such as coverage summaries or result statistics. Keep it non-time-consuming.

### `check_phase(uvm_phase phase)`

Perform final consistency checks after runtime activity. Report failures with UVM reporting macros, for example `` `uvm_error `` or `` `uvm_fatal ``. A scoreboard should usually perform transaction-by-transaction checking during runtime; `check_phase` is useful for final checks such as ensuring no expected transactions remain unmatched.

### `report_phase(uvm_phase phase)`

Print a concise test result or summary. UVM's report server also produces the standard report summary after the component report callbacks.

### `final_phase(uvm_phase phase)`

Perform final non-time-consuming cleanup. Do not use it to run more stimulus or wait for simulation events.

## 8. Complete illustrative component example

This example demonstrates hierarchy creation, connection, runtime stimulus, objections, and a final check. Names such as `my_agent`, `my_scoreboard`, and `my_sequence` represent user-defined UVM classes.

```systemverilog
class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  my_agent     agent;
  my_scoreboard scoreboard;

  function new(string name = "my_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = my_agent::type_id::create("agent", this);
    scoreboard = my_scoreboard::type_id::create("scoreboard", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.ap.connect(scoreboard.analysis_export);
  endfunction
endclass

class my_test extends uvm_test;
  `uvm_component_utils(my_test)

  my_env env;

  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = my_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    my_sequence seq;

    phase.raise_objection(this, "run the test sequence");
    seq = my_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    phase.drop_objection(this, "test sequence completed");
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (env.scoreboard.has_unmatched_transactions())
      `uvm_error("FINAL_CHECK", "Scoreboard has unmatched transactions")
  endfunction
endclass
```

The code is illustrative and assumes the agent has `monitor.ap` and `sequencer`, the scoreboard has `analysis_export` and `has_unmatched_transactions()`, and the sequence is compatible with that sequencer.

## 9. `run_phase` versus the task-based runtime phases

| `run_phase` | Named runtime phases (for example, `reset_phase`, `main_phase`) |
|---|---|
| A single task callback commonly used for testbench activity | A structured runtime schedule with separate responsibilities |
| Convenient for straightforward tests and examples | Helpful when components need coordinated reset/configure/main/shutdown behavior |
| Often used to start a sequence and hold an objection until it completes | Can express phase-specific behavior and use phase-aware sequences |
| Runs as part of the UVM runtime phasing system | Execute within the runtime schedule; do not treat them as ordinary sequential calls from `run_phase` |

Choose one clear runtime strategy for the environment. Avoid unintentionally starting the same stimulus from both `run_phase` and `main_phase`.

## 10. Common interview questions and answers

### Q1. What is the difference between a function phase and a task phase?
A function phase cannot consume simulation time and is used for operations such as creating components or connecting TLM ports. A task phase can consume time and is used for reset, stimulus, and timed behavior.

### Q2. Why should components be created in `build_phase`?
The hierarchy is created during the build stage, which is designed for top-down component construction and configuration. Later phases expect the hierarchy to exist.

### Q3. What is the difference between `build_phase` and `connect_phase`?
`build_phase` creates/configures components. `connect_phase` connects ports, exports, and other communication paths after components have been created.

### Q4. Why call `super` in an overridden phase method?
It preserves the parent class's phase behavior. Omitting it can silently skip functionality implemented by a base UVM class or an intermediate user-defined class.

### Q5. What is an objection, and why is it needed?
It indicates that a component still has work to do in a runtime phase. The phase remains active until objections are dropped and the phase engine is able to complete the phase.

### Q6. What happens if an objection is never dropped?
The runtime phase may never end, so the test can appear hung. Inspect objection ownership and trace raise/drop activity.

### Q7. Can a function phase contain a delay?
No. Function phases must not consume simulation time. Put timed behavior in a task phase.

### Q8. When should a scoreboard check transactions?
Usually as transactions arrive during runtime. Use `check_phase` for final checks, such as confirming that expected and actual queues are empty or matched.

### Q9. Is `run_phase` the same as `main_phase`?
No. `run_phase` is the common runtime task callback. `main_phase` is one phase in the structured runtime schedule. They are coordinated by UVM phasing and should not be assumed to be a simple sequential chain.

### Q10. Why is `build_phase` top-down?
A parent creates its children first; then each child can execute its own build callback and create its descendants.

### Q11. Why use the UVM factory's `type_id::create`?
It enables factory overrides, allowing a test to substitute implementations without changing the environment's construction code.

### Q12. Where should reset code go?
For simple testbenches it may be managed by a reset sequence started during runtime. Environments using the structured runtime schedule can put reset behavior in `reset_phase`. Choose a consistent approach and ensure dependent components coordinate correctly.

## 11. Practical checklist and common mistakes

- Create components in `build_phase`; connect them in `connect_phase`.
- Use `uvm_config_db` or another intentional configuration mechanism rather than relying on fragile hierarchical references.
- Use factory creation for components that should support overrides.
- Call `super.<phase>(phase)` in overridden callbacks unless there is a deliberate reason not to.
- Keep function phases free of timing controls.
- Raise objections before phase-dependent work and drop them after required work and checks are complete.
- Do not leave an objection raised on an error path; use robust control flow for cleanup.
- Do not use arbitrary `#delay` values as a replacement for protocol events or completion handshakes.
- Avoid duplicate stimulus from both `run_phase` and a named runtime phase.
- Put final scoreboard consistency checks in `check_phase`, while keeping normal transaction comparisons in runtime.
- Use the UVM topology print and report/objection tracing to debug construction and phase completion.

## 12. Quick phase summary

```text
build_phase             : create/configure components (function, top-down)
connect_phase           : connect TLM interfaces (function)
end_of_elaboration_phase: inspect/finalize hierarchy (function)
start_of_simulation_phase: last pre-runtime setup (function)
run_phase               : common runtime task callback
reset/configure/main/...: structured runtime task phases
extract_phase           : gather final data (function)
check_phase             : final checks (function)
report_phase            : summarize results (function)
final_phase             : final cleanup (function)
```
