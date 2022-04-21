# Ministrel

**Ministrel** is a toy synchronous language for reactive programming highly inspired by
[Esterel](https://en.wikipedia.org/wiki/Esterel).
Its implementation closely follows the idea presented in the lecture ["Esterel de A à Z"](https://www.college-de-france.fr/site/gerard-berry/course-2017-2018.htm).

## What is a synchronous language ?

Some computer systems need to continuously provide outputs to react to their environment.
Such systems are called [*reactive systems*](https://en.wikipedia.org/wiki/Synchronous_programming_language).

Due to their very sequential model of computation, usual programming languages such as C, Java or ML are typically not well adapted to design reactive programs. Synchronous languages, such as Esterel, offer a completely different programming paradigm especially intended to make the task of developing and reasoning about reactive systems easier. In Esterel, for example, the base building block is the notion
of signal: an Esterel program continuously reacts to input signals by emitting output signals.
Together with well chosen constructs to handle signals and combine programs, this "simple"
idea gives a very expressive language that can be use to model reactive systems in a compact
and elegant way.

## An example of reactive system

Let's take a very basic example to demonstrate the beauty of synchronous languages and their
ability to model reactive systems. The example we consider is called *ABRO* and is known to be the *hello world* of synchronous programming.

The specification of the system is as follows:

1. We consider 2 input signals `A`, `B` and one output signal `O`
2. If the user inputs an `A` and a `B`, the system outputs `O` and resets itself.
Here, `A` and `B` means either `A` followed by `B`, or `B` followed by `A`, or both `A` and `B` at the same time.
3. At any point in time, if the user inputs `R`, the system resets itself

In Esterel (and in **Ministrel**), this system can me modeled by the following very concise synchronous program:

```
loop
  abort
    { await A || await B };
    emit O;
    halt
  when R
end
```

Let's analyse the structure of this program step by step. First, the system is expected to run continuously. To do so, we use a `loop`. So far, nothing really new there.
The body of the loop is more interesting.
According to the specification, the system is supposed to reset itself each time an `R` is provided as an input signal. To handle this, we use the `abort ... when R` construct. Informally, `abort p when R` starts the execution of `p` and, if `R` is detected while `p` is executing, `p` is interrupted.

Given this new construct `abort`, we can now discuss the most important part of the program:

```
{ await A || await B };
emit O;
halt
```

There are a lot of new things here. First, the `await` instruction. `await S` block the execution until a signal `S` is detected.
Then, the parallel operator `||` is used to compose `await A` and `await B`. In Esterel, 2 programs running in parallel have access to the exact same inputs and they receive every signal EXACTLY at the same time. In our case, `await A || await B` is going to run until both `A` and `B` are detected (either both at the same time, or one after the other). As soon as `A` and `B` have been received, a signal `O` is emitted thanks to the instruction `emit O`.
After emitting, the program can idle. We will come back to the `halt` instruction in more details later.

## A weird notion of time

Reactive systems are all about time. Over time, signals are emitted and the system react to them. To simplify things a little bit, we consider that the time is discrete and that an environment is just an infinite sequence of finite sets of signals. The output of a program is an infinite sequence of finite sets of signals.

For example, an environment for our system ABRO could be the sequence `{} {} {A B} {R} {A} {B} {R} ...` (no signal is emitted during the 2 first time units, `A` and `B` are emitted at time 3, `R` is emitted at time 4 and so on...).

The key idea in Esterel, is that basic actions take **no time** to execute. For example, the program `emit A; emit B` is going to emit `A` and `B` within the first unit of time (resulting in the sequence `{A B} ...`). This sounds counterintuitive and unrealistic, but modeling systems as if actions are executed in no time is actually what makes Esterel so elegant. However, there is one exception: the instruction `pause` is the only instruction that takes 1 unit of time to execute. The `pause` instruction can therefore be used to synchronise programs and to control which subprograms are executed at the same time or not. For example, the program `loop { emit A; pause } end` gives the output `{A} {A} ...`.
However, the program `loop { emit A } end` is forbidden because the loop body takes no time to execute. Executing such a program would lead to the production of infinitely many output signals within 0 unit of time.

Reactive programs are not expected to terminate: they should run continuously. Therefore, a program that is *done computing* is simply a program that is not reacting to input signals. This behavior can be obtained 
by looping while doing nothing:

```
loop
  nothing
end
```

However, as explained above, basic actions take no time to execute. 
The instruction `nothing` is no exception and therefore, such a loop would be ill-formed (remember that the body of a loop must take at list 1 unit of time to execute). To model the idea of *doing nothing during 1 unit of time*, we introduce an instruction `pause`. From pause we can derive an instruction `halt` causing the program to idle, continuously ignoring the inputs:

```
halt = loop
  pause
end
```

## Syntax

So far, we discussed a complete example and we talked about time in reactive programs. Let's be a little more formal and introduce the syntax of the language **Ministrel**.

To keep the implementation as concise as possible, we introduce very few primitives in our language. However, these primitives are powerful enough to derive more expressive instructions. For convenience, **Ministrel** features supports derived instructions (but they are unfolded to their definition internally).

### Basic Instructions

#### `nothing` and `pause`

The instruction `nothing` does nothing in 0 unit of time. The instruction `pause` does nothing but takes 1 unit of time.

#### Emitting signals

To emit a signal `S`, one can use the instruction `emit S`. Note that this instruction, as any instruction (except for `pause`) takes no time to execute.

#### Testing for signals

The main interest of reactive programs is, well..., to react to signals ^^'. To react to an input signal `S`, one can use an `if then else` structure.

```
if S then
  p
else
  q
end
```

This test if the input signal `S` is currently present. If so, `p` is executed, otherwise `q` is executed. Easy right?

### Preemption

One of the most important feature that makes Esterel so expressive is its ability to not only detect and emit signals but also to suspend the execution of a sub-program in reaction to the environment. In computer science, this is referred to as *preemption*. 

**Ministrel** provides 2 primitives for preemption: `suspend` and `trap`.

#### Suspending a program

The `suspend` primitive allows to freeze the execution of a program `p` each time a signal `S` is present. The program is resumed as soon as `S` is no longer detected. The syntax is as follows:

```
suspend
  p
when S
```

Note that `suspend` does not take effect immediately but only starting from the next time unit.

For example, let's consider the following program:

```
suspend
  loop
    emit A; pause
  end
when S
```

Let's consider the following sequence of input signals: `{S} { } {S} { } ...`. `S` is present at time 0 but `suspend` ignores signals that are present when it starts executing. Therefore, `A` is still emitted at time 0. Then, since `S` is no longer present at time 1, `A` is again emitted. However, at time 2, `S` is detected and therefore the program is suspended until time 3. The sequence of outputs will look like `{A} {A} { } {A} ...`.

#### Traps

Another powerful mechanism to control the execution of programs in reaction to signals is traps. Traps are similar to exceptions in Java or OCaml. Traps are emitted by the instruction `exit` and handled by the instruction `trap`:

```
trap T
  ...
  exit T
  ...
end
```

When `exit T` is executed, the handled program is interrupted. Note that the program is not interrupted immediately but at the next time unit. This is called *weak preemption*.

The actual syntax of **Ministrel** requires to specify an integer index (`>= 2`) after an `exit`. For example, `exit T 3`. This is to handle nested traps handling.

```
trap T
  ...
  trap T
    ...
    exit T 2
    ...
  end;
  emit A
end;
emit B
```

In the above example, the `2` in `exit T 2` refers to the first trap handler above the `exit` instruction. Therefore, after the `exit` instruction is executed, the program is going to emit `A`.

```
trap T
  ...
  trap T
    ...
    exit T 3
    ...
  end;
  emit A
end;
emit B
```

This second program, however, is going to emit `B` if the `exit` is executed.


### Table des instructions

| Instructions                  |                                                                          |
| :---------------------------- | :----------------------------------------------------------------------- |
| `nothing`                     | Do nothing in 0 unit of time                                             |
| `pause`                       | Do nothing in 1 unit of time                                             |
| `emit S`                      | Emit a signal `S` instantly                                              |
| `loop p end`                  | Repeat the execution of `p`                                              |
| `trap T p end`                | Trap `T` in `p`                                                          |
| `exit T k`                    | Trigger the `k`-th outermost trap                                        |
| `if S then p else q end`      | Test the signal `S` and executes `p` or `q` accordingly                  |
| `p ; q`                       | Execute `p` and then `q`                                                 |
| <code>p &#124;&#124; q</code> | (Synchronous) Parallel composition of `p` and `q`                        |
| `suspend p when S`            | Suspend the execution of `p` if `S` is present                           |
| `abort p when S`              | Start execute `p` and abort the execution as soon as when `S` is present |

### Unsupported features (yet)

Some interesting features are not yet supported in *Ministrel*. To name a few:

+ [ ] `immediate` variants for `abort` and `suspend` to take effect without delay
+ [ ] local signals declarations
+ [ ] module system
+ [ ] compiler from **Ministrel** to automaton

## References

+ [Esterel de A à Z](https://www.college-de-france.fr/site/gerard-berry/course-2017-2018.htm), G. Berry
+ [Principes, idées et styles pour la programmation réactive](https://www.college-de-france.fr/site/gerard-berry/course-2018-02-07-16h00.htm), G. Berry
+ [Sémantiques, causalité et constructivité des langages synchrones](https://www.college-de-france.fr/site/gerard-berry/course-2018-02-14-16h00.htm), G. Berry
+ [The Constructive Semantics of Pure Esterel](https://www.college-de-france.fr/media/gerard-berry/UPL1145408506344059076_Berry_EsterelConstructiveBook.pdf), G. Berry

*A big thank you to G. Berry for being such an amazing and passionate lecturer. His lectures on Esterel given at "Collège de France" were so good I could not resist implementing the content of the lecture*