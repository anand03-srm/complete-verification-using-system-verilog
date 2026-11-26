# UVM Phases — Simple Interview Guide

This guide explains UVM phases in plain language: what each phase does, why it is used, and where you would write code. It includes examples and common interview questions.

> **About the shared link:** I can’t read the contents of that ChatGPT share directly. I’ve rewritten this guide in simpler, more conversational language based on your request. If there is a specific explanation from the link you want followed, paste it here and I can match it more closely.

## 1. What is a UVM phase?

Think of a UVM testbench like a team getting ready to run a test. First, the team creates all its parts. Next, the parts are connected. Then the test runs. Finally, the team checks and reports the result.

UVM phases are the **standard steps that organize this work**. The UVM library calls the phase methods for you. You write the code that should happen at each step; you normally do not call phase methods yourself.

For example:

- Create an agent in `build_phase`.
- Connect the agent to a scoreboard in `connect_phase`.
- Run a sequence in a runtime phase.
- Check for leftover transactions in `check_phase`.

A component can take part in a phase by implementing its phase method. If it does not need to do anything in a phase, it can leave that method out.

## 2. Two important kinds of phase methods

### Function phases

A function phase must finish immediately. It **cannot wait for time to pass**. Use it for setup and checks that do not need simulation time, such as creating components or connecting ports.

Examples: `build_phase`, `connect_phase`, `check_phase`.

### Task phases

A task phase can wait for a clock, wait for an event, or start time-consuming activity. Use it for reset and stimulus.

Examples: `run_phase`, `reset_phase`, `main_phase`.

**Interview tip:** If a phase method is declared `function`, do not put `#delay`, `@(posedge clk)`, or another wait inside it. Timed behavior belongs in a task.

## 3. The usual UVM phase order

The main steps usually look like this:

```text
build_phase
connect_phase
end_of_elaboration_phase
start_of_simulation_phase
runtime phases (including run_phase)
extract_phase
check_phase
report_phase
final_phase
```

In plain terms: **create → connect → inspect → start → run → collect → check → report → finish**.

The runtime schedule can include reset, configuration, main traffic, and shutdown. A simple test may use `run_phase`; a larger testbench may use the more detailed runtime phases.

## 4. Setup and preparation phases

### `build_phase`

**Simple definition:** Create the testbench components and get the settings they need.

This is where a test creates its environment, and an environment creates its agents and scoreboard. The hierarchy is built from parent to child, so it is called **top-down**.

```systemverilog
function void build_phase(uvm_phase phase);
  super.build_phase(phase);

  agent = my_agent::type_id::create("agent", this);

  if (!uvm_config_db#(virtual bus_if)::get(this, "", "vif", vif))
    `uvm_fatal("NOVIF", "Virtual interface was not configured")
endfunction
```

`type_id::create` creates a component through the UVM factory, which allows a test to substitute another implementation with a factory override. `super.build_phase(phase)` calls the parent class's build behavior too.

### `connect_phase`

**Simple definition:** Join the components together after they have been created.

For example, connect a monitor's analysis port to a scoreboard's analysis export. This is a function phase, so it cannot wait for simulation time.

```systemverilog
function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  agent.monitor.ap.connect(scoreboard.analysis_export);
endfunction
```

**Interview difference:** `build_phase` creates components; `connect_phase` connects them.

### `end_of_elaboration_phase`

**Simple definition:** The testbench has been built and connected; this is a chance to inspect the finished setup.

For example, print the component hierarchy or check that required components exist. This is a function phase.

### `start_of_simulation_phase`

**Simple definition:** Do final non-timed setup just before runtime activity begins.

It is useful for a final message or setup that depends on the completed hierarchy. Do not use it to wait for reset or drive timed signals; it is a function phase.

## 5. Runtime phases: where timed work happens

Runtime phases are task phases. They are used for work that takes simulation time, such as driving reset, programming the DUT, or sending transactions.

The standard runtime schedule has these named phases:

| Phase | In simple words | Example responsibility |
|---|---|---|
| `pre_reset_phase` | Get ready to reset | Prepare reset-related components |
| `reset_phase` | Put the DUT into a known state | Assert and release reset |
| `post_reset_phase` | Finish reset handling | Wait for the DUT to settle |
| `pre_configure_phase` | Get ready to configure | Prepare configuration sequences |
| `configure_phase` | Set up the DUT | Program registers or operating modes |
| `post_configure_phase` | Finish configuration | Confirm settings are ready |
| `pre_main_phase` | Get ready for normal traffic | Prepare the main test sequence |
| `main_phase` | Run the main test | Send normal transactions |
| `post_main_phase` | Finish normal traffic | Stop traffic or drain remaining work |
| `pre_shutdown_phase` | Get ready to finish | Prepare components for shutdown |
| `shutdown_phase` | Complete outstanding work | Finish pending operations or return to idle |
| `post_shutdown_phase` | Finish runtime activity | Complete final runtime cleanup |

Not every testbench needs custom code in every named runtime phase. These phases are most helpful when the environment needs a clear separation between reset, configuration, traffic, and shutdown.

### `run_phase`

**Simple definition:** A commonly used runtime task where a test starts stimulus and waits for it to finish.

```systemverilog
task run_phase(uvm_phase phase);
  phase.raise_objection(this, "Test is running");

  // Start a sequence or wait for test activity to complete.
  repeat (10) @(posedge vif.clk);

  phase.drop_objection(this, "Test activity is complete");
endtask
```

`run_phase` is a task, so it can wait for clock edges and run sequences. It is not a synonym for `main_phase`. `run_phase` is the common runtime callback; `main_phase` is one phase in the more detailed runtime schedule.

### Example of a reset phase

```systemverilog
task reset_phase(uvm_phase phase);
  phase.raise_objection(this, "Applying reset");
  drive_reset();
  wait_for_reset_release();
  phase.drop_objection(this, "Reset is complete");
endtask
```

This is illustrative: `drive_reset()` and `wait_for_reset_release()` must be implemented by the component. In a reusable environment, reset is often driven through a sequence and driver rather than by directly driving signals in many places.

## 6. Objections: how UVM knows the test is not finished

An **objection is a way for a component to tell UVM, “I still have work to do; please don’t end this runtime phase yet.”**

The usual pattern is:

1. Raise an objection before the work starts.
2. Do the work and wait for it to finish.
3. Drop the objection when the work is done.

```systemverilog
phase.raise_objection(this, "Starting sequence");
seq.start(env.agent.sequencer);
phase.drop_objection(this, "Sequence finished");
```

When all objections are dropped, UVM can let the phase finish. If an objection is never dropped, the simulation may look stuck because the phase is still waiting for that component.

**Remember:** Starting background activity and immediately dropping the objection may let the phase end before that activity is done. Keep the objection raised until all required work has completed. A drain time can allow remaining activity to settle, but it does not replace raising and dropping objections correctly.

## 7. End-of-test phases

These function phases happen after runtime activity. They do not consume simulation time.

### `extract_phase`

**Simple definition:** Gather final information from the test, such as coverage or statistics.

### `check_phase`

**Simple definition:** Do final checks to see whether the testbench ended in a valid state.

A scoreboard normally compares transactions while the test is running. In `check_phase`, it can check that no expected transactions were left unmatched.

```systemverilog
function void check_phase(uvm_phase phase);
  super.check_phase(phase);
  if (has_unmatched_transactions())
    `uvm_error("FINAL_CHECK", "Some transactions were not matched")
endfunction
```

### `report_phase`

**Simple definition:** Print a summary of the test result or useful statistics.

UVM also prints its report summary through its report infrastructure.

### `final_phase`

**Simple definition:** Do final cleanup that does not need simulation time.

Do not start new timed stimulus or wait for events here.

## 8. Putting phases together: a small example

This example shows an environment creating and connecting components, then a test starting a sequence and checking the final result. `my_agent`, `my_scoreboard`, and `my_sequence` stand for user-defined classes.

```systemverilog
class my_env extends uvm_env;
  `uvm_component_utils(my_env)

  my_agent      agent;
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

    phase.raise_objection(this, "Running test sequence");
    seq = my_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    phase.drop_objection(this, "Test sequence finished");
  endtask

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (env.scoreboard.has_unmatched_transactions())
      `uvm_error("FINAL_CHECK", "Scoreboard has unmatched transactions")
  endfunction
endclass
```

This is an example of phase structure, not a complete compilable testbench. It assumes the agent has a monitor analysis port and sequencer, and the scoreboard provides the shown export and check method.

## 9. Common interview questions

### What is a UVM phase?
A standard step in the testbench lifecycle. UVM calls the phase callback so components can do their setup, runtime work, or final checks at the right time.

### What is the difference between `build_phase` and `connect_phase`?
`build_phase` creates components and gets their configuration. `connect_phase` connects components that have already been created.

### Why is `build_phase` top-down?
The parent needs to create its child components first. Then each child can build its own children.

### Why do we call `super.build_phase(phase)`?
It lets the parent class perform its own build work. Without it, that inherited behavior may be skipped.

### What is the difference between a function phase and a task phase?
A function phase cannot wait or consume time. A task phase can wait for events and perform timed activity.

### What does an objection do?
It tells UVM that a component still has work to do, so the runtime phase should not end yet.

### What happens if an objection is not dropped?
UVM may keep waiting, and the test can appear to hang.

### Is `run_phase` the same as `main_phase`?
No. `run_phase` is a common runtime callback. `main_phase` is part of the structured runtime schedule. They are different callbacks; do not start the same stimulus in both by accident.

### Where should scoreboard checking happen?
Compare transactions as they arrive during runtime. Use `check_phase` for final checks, such as looking for leftover unmatched transactions.

### Can I use a delay in `build_phase`?
No. `build_phase` is a function phase. Timed behavior belongs in a task phase.

## 10. Quick revision sheet

```text
build_phase              Create components and get configuration
connect_phase            Connect the components
end_of_elaboration_phase Inspect the completed testbench
start_of_simulation_phase Do final setup before runtime
run_phase                Common task callback for runtime work
reset/configure/main/... Separate runtime responsibilities when needed
extract_phase            Gather final results and statistics
check_phase              Check final testbench state
report_phase             Print a result summary
final_phase              Do final non-timed cleanup
```

**Easy way to remember it:** Build the team, connect the team, run the test, check the result, and report what happened.
