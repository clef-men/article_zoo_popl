> POPL 2026 Paper #427 Reviews and Comments
> ===========================================================================
> Paper #427 Zoo: A framework for the verification of concurrent OCaml 5
> programs using separation logic
> 
> 
> Review #427A
> ===========================================================================
> 
> Overall merit
> -------------
> A. Good paper, I will champion it
> 
> Reviewer expertise
> ------------------
> X. Expert
> 
> Paper summary
> -------------
> This paper presents Zoo, a framework for verifying concurrent OCaml
> programs. Zoo is built on top of the Iris separation logic
> framework. Since Iris is already a highly expressive separation logic,
> the challenge in developing a tool like Zoo lies not in coming up with
> an extension to separation logic per se, but rather in building
> a faithful model of the semantics of the subset of OCaml supported by
> the framework and then deriving suitable reasoning rules on top. It
> turns out that doing so caused the authors to discover a number of
> subtleties and corner cases in concurrent OCaml, which then led to
> them developing new extensions/changes to OCaml, some of which have
> been upstreamed and are slated for release. To demonstrate Zoo's
> effectiveness, the authors have used it to verify several libraries
> for concurrent data structures from OCaml, uncovering bugs related to
> the above subtleties in some of these libraries.
> 
> Comments for authors
> --------------------
> Strengths:
> - Large enough subset of OCaml supported to be able to verify several
>   real libraries
> - Verification framework led to
>   improvements/enhancements/clarifications for concurrent OCaml, which
>   are well described.
> 
> Weaknesses:
> - Does not yet handle weak memory semantics, so in some sense it is
>   not "sound" (but there are probably lots of interesting bugs to be
>   found even in an SC framework)
> 
> Thank you for your submission to POPL. This is a very nice paper, and
> I learned many interesting facts about concurrent OCaml while reading
> it. I think the tool described here will be quite useful to the
> community and could serve as a foundation for lots of interesting
> follow-up work.
> 
> While there have been various separation-logic based tools built with
> Rocq for verifying programs from different languages (e.g. CFML, VST,
> Perennial/Goose, RefinedC), a very nice thing that distinguishes Zoo
> from these other works is that it led the authors to clarify/enhance
> several aspects of concurrent OCaml, some of which have already been
> merged into OCaml. The paper does a nice job of describing the design
> considerations and details behind these issues, which I think will
> make the paper of more general interest beyond just the separation
> logic/verification community.
> 
> *Detailed Comments*:
> 
> - Section 3.2 -- after reading this, I understand the problem being
>   described, but I still didn't understand what solution you
>   selected. Perhaps you can describe the reduction rules?
> 
> - Section 3.3 -- I get why SC makes it sound to translate
>   Atomic.get/Atomic.set to just loads/stores, but what I am confused
>   about is, does that mean you don't have "plain" references at all?
>   I.e. there's nothing that corresponds to the usual non-atomic "!"
>   operator in OCaml?
> 
> - Section 3.4 -- The opening of section 3 says it is about the
>   "salient features of Zoo, which we found lacking when we attempted
>   to use HeapLang", but 3.4 is just describing standard Iris prophecy
>   variables with no changes.
> 
> - Section 4.1 -- I don't think the full chronology of when things were
>   implemented is really necessary/the best use of space.

Our intent was to suggest, in a fact-based way, that getting features integrated in the upstream OCaml compiler is in fact a significant source of work. (This is also a form of impact of our research, and letting our academic colleagues have a bird eye's view of the dynamics involved could be of interest to some.)

> - Lines 600 - Lines 604: I think you should spell out the reason why
>   Some 0 == Some 0 can return false, for people who do not already
>   know why.
> 
> - Lines 618-620 -- but then doesn't the manual's described guarantee
>   contradict what's going on with the Any example in lines 594-599?

OCaml implementations that validate the physical equality `Any false == Any 0` also validate the structural equality `Any false = Any 0`: structural equality is defined on untyped representations and can relate values of different types.

> - Fig 4 -- something seems misformatted about these specifications,
>   are they supposed to be atomic triples? in my PDF viewer they're
>   just rendered as having horizontal line sseparating the
>   precondition/program/postcondition, without brackets.
> 
> - Lines 948-951: I wouldn't really describe these as a "flaw" of those
>   stack examples, since using the pointers as they do makes them
>   closer to how those data structures are implemented in languages
>   like C or what you see in the algorithms papers describing those
>   examples. But you're absolutely right that it's not a good model of
>   an efficient/idiomatic OCaml implementation.

There are several ways to interpret your remark: "closer to C" could be in terms of programming style, or in term of data layout and in-memory representation. In this paragraph, and we expand a bit on this in the specific case of the Michael-Scott queue below, we emphasize that HeapLang programs have a *different* memory layout / data representation from textbook implementations in C/C++ (or Java, OCaml, etc.), due to the insertion of an *additional* pointer indirection in each node, which is specifically added to work around the restricted semantics of compare-and-swap in HeapLang.

This is non-obvious, but clearly shown in the Figure 2 of the Vindum-Birkdel-2021 paper ( https://www.cs.au.dk/~birke/papers/2021-ms-queue.pdf ), we cite their description of this extra indirection explicitly.

For a different example, consider the following implementation of a Treiber stack in the iris/examples repository:
  https://gitlab.mpi-sws.org/iris/examples/-/blob/426893b7d67cd4456f89337d9163b3b4a91734d0/theories/concurrent_stacks/concurrent_stack1.v#L9

```
Definition new_stack : val := λ: "_", ref NONEV.
Definition push : val :=
  rec: "push" "s" "v" :=
    let: "tail" := ! "s" in
    let: "new" := SOME (ref ("v", "tail")) in
    if: CAS "s" "tail" "new" then #() else "push" "s" "v".
Definition pop : val :=
  rec: "pop" "s" :=
    match: !"s" with
      NONE => NONEV
    | SOME "l" =>
      let: "pair" := !"l" in
      if: CAS "s" (SOME "l") (Snd "pair")
      then SOME (Fst "pair")
      else "pop" "s"
    end.
```

For example `pop` first dereferences the mutable reference `s` and
reads its value, then performs a second dereference on `l` when the
stack is non-empty to be able to access the list cell, which is itself
a (boxed) pair so a third dereference is implicit in `Fst "pair"` to
get the first element of the list. (The Some constructor around `l`
does not introduce a pointer indirection, as Heaplang assumes an
optimized tagged encoding for disjoint sums constructor with
a location payload; see
https://gitlab.mpi-sws.org/iris/iris/-/blob/c5014d246b2cc5d1bf79d3ba362501dd7b447f74/iris_heap_lang/lang.v#L148
for a documentation of the assumed HeapLang value representation.)

One would naively think of erasing the extra indirection in HeapLang by writing the following:

```
Definition new_stack : val := λ: "_", ref NONEV.
Definition push : val :=
  rec: "push" "s" "v" :=
    let: "tail" := ! "s" in
    let: "new" := SOME ("v", "tail") in
    if: CAS "s" "tail" "new" then #() else "push" "s" "v".
Definition pop : val :=
  rec: "pop" "s" :=
    match: !"s" with
      NONE => NONEV
    | SOME "pair" =>
      if: CAS "s" (SOME "pair") (Snd "pair")
      then SOME (Fst "pair")
      else "pop" "s"
    end.
```

This program would be morally correct, and it does correspond to the version that we verify in OCaml, but it is not a valid HeapLang program: the HeapLang semantics allow calling compare-and-set on a value of type `UnboxedOption<Ref<...>>`, but *not* on a value of type `UnboxedOption<Pair<...>>` (or `Pair<...>`).

We do believe that adding extra indirections in the memory layout, and corresponding allocations/dereferences in the implementation (adding noise to already-tricky code), is a "flaw" of the HeapLang implementations of these structures. It makes them (less efficient and) more distant from the textbook implementation. See for example the textbook Java implementation on Wikipedia ( https://en.wikipedia.org/wiki/Treiber_stack ):

```java
public E pop() {
    Node<E> oldHead;
    Node<E> newHead;

    do {
        oldHead = top.get();
        if (oldHead == null)
            return null;
        newHead = oldHead.next;
    } while (!top.compareAndSet(oldHead, newHead));

    return oldHead.item;
}
```

The check `oldHead == null` corresponds to the match on `!s`, but `oldHead` is directly a (boxed) pair, with no need for an extra dereference `!l` to get the pair.

(Implementations of the Treiber stack in C/C++ are obscured along an orthogonal dimension, as they typically implement manual pointer versioning to avoid the ABA problem -- which is typically not an issue in GC-ed languages such as OCaml and Java. This makes comparing to C/C++ code harder, but it does not change the amount of pointer indirection in the structure.)

> - Line 1031: "proposed the additional of", should say "addition"
> 
> - Line 1044: "pritive"
> 
> - Section 11.1 -- I think it might be helpful just to clarify that of
>   course, in the end, since you don't have a model of the type system,
>   the guarantee you're getting here is not quite as strong as full
>   type safety/memory safety for any well typed client, as one would
>   get in RustBelt.
> 
> - Lines 1164 - 1167 : does Osiris have any advantages / different
>   design decisions that are pertinent, other than the non-treatment of
>   concurrency?
> 
> - Lines 1168 : "At the time of writing", I would say "Prior to our work"
> 
> Specific questions to be addressed in the author response
> ---------------------------------------------------------
> 1. Can you say anything about whether your [@generative] directive
>    might be possibly merged, as your other proposed changes were? Or
>    are there drawbacks/design considerations that prevent that?

We have not started this discussion yet. `[@generative]` is a much
simpler change to implement than (say) atomic record fields, it
suffices to ask the compiler to pretend that the fields of the
constructor are mutable instead of immutable. So we hope that it could
be easier to gather consensus, and feel optimistic that it could be
received positively by compiler maintainers.

Our main non-upstreamed change currently is the support for atomic
arrays. It builds on top of the now-merged machinery for atomic record
fields, so it is less invasive than atomic fields were. But it will
require more review work and discussion than generative constructors:

- Example of non-scientific questions that will take some time to be
  discussed are: should this be an Atomic.Array submodule, or maybe an
  Array.Atomic submodule, or a first-level Atomic_Array module?
  Should the new module export many helpful functions as the main
  Array module does, or just the bare primitives necessary to
  manipulate arrays in user code?

- On the more technical side, our patch introduces a new compiler
  primitive for array bound checking separately of array access (to be
  able to reuse it for atomic-array accesses; the OCaml backend uses
  a specific code-generation strategy to reduce code size for array
  bound accesses, and we would want to benefit from it as well), and
  we could expect some discussion with backend experts on the
  right/better way to do this.
  
- Some functions of the (non-atomic) Array module are implemented in
  C for efficiency reasons (`Array.blit`, `Array.sub`), reviewers
  could consider asking for the same effort on atomic arrays. On the
  other hand, it is unclear that these functions should be provided in
  the first place, as they would not operate atomically on their
  atomic array arguments.


> Review #427B
> ===========================================================================
> 
> Overall merit
> -------------
> B. OK paper, but I will not champion it
> 
> Reviewer expertise
> ------------------
> X. Expert
> 
> Paper summary
> -------------
> The authors present Zoo, a framework for reasoning about fine-grained
> concurrent OCaml 5 algorithms. For this, the authors first introduce
> ZooLang as formal version of OCaml with an automatic translation from
> OCaml programs. Then, the authors present an Iris-based separation
> logic for ZooLang and use it to verify a set of programs from the
> Saturn and Eio OCaml libraries. In the process, the authors discover
> that these libraries are not sound. To fix this, the authors propose
> and develop extensions of OCaml.
> 
> Comments for authors
> --------------------
> Strengths:
> + Contributions to the OCaml compiler
> + Physical equality
> + Evaluation on OCaml libraries
> 
> Weaknesses:
> - Written at a high level without technical detail
> - Only sequential consistency

> - Many references to private communication

Most of this work happened in public, but we had to hide the references to specific issues/PRs from the present submission as they would rather directly contradict the POPL instructions to carefully preserve anonymity. For example, we followed the standard *public* RFC process to discuss the design of Atomic record fields, and our local non-anonymous version of our paper of course links to our RFC and the following discussion, but providing this link to POPL reviewers would immediately de-anonymize some of the authors.

> - No evaluation of the semantics and discussion of the fragment
> 
> Main Comments:
> 
> Verification research often targets algorithms in abstract and
> idealized forms. This paper addresses the challenges of translating
> these theoretical results into practice-a task that proves far from
> trivial. The authors expose multiple deficiencies in OCaml that
> complicate the implementation of correct concurrent algorithms. These
> issues extend beyond theoretical concerns: the authors discover actual
> errors in existing OCaml concurrency libraries. They develop solutions
> to these problems, with one fix being incorporated into mainline
> OCaml. Furthermore, the authors identify issues with the specification
> of physical equality in concurrent algorithms and create a compiler
> extension to resolve them.  Using these extensions, the authors verify
> a wide range of concurrent algorithms from the Saturn and Eio
> libraries.
> 
> On the surface, this seems like a very strong paper and with a solid
> technical contribution. However, the authors fail to present these
> impressive technical contributions in the paper.  The paper reads more
> like an experience report by the authors than a POPL paper describing
> the technical contributions.  When reading a POPL paper, I do not just
> expect reading what the authors did, but also to understand how the
> authors achieved their results, and what the insights are that are
> generally useful, even for people not directly working with OCaml.

One point to note in our defense is that the present submission is
accompanied by an extensive Rocq development, which (we made available
on submission on) intend to remain permanently linked to the paper,
covering both the Zoo formalization and the various verified
data-structures whose verification is claimed as a contribution. Any
additional technical detail that would unfortunately be missing from
the paper can be recovered (with some effort) from this mechanized
development, which we believe follows reasonable standards of
readability and maintenability.

This being said, we did try to emphasize some valuable lessons that
reach outside the OCaml community:

- In section 3 we list salient language features that we encountered
  in concurrent OCaml code in practice, or in their verification, and
  in particular the centrality of physical equality. We would expect
  this to be relevant to people interested in verifying lock-free
  concurrent code in other functional languages such as Lisp/Scheme,
  Haskell, Scala, etc.

- The question of how to formalize physical equality similarly applies
  to all languages that offer composite/structured data structures
  with a mix of mutable and immutable constructors. (More precisely,
  immutable blocks without an identity.)

- We did not have the space to detail the verification arguments of
  the data-structures we verified, but we do consider their complete
  verification (and in particular the invariants that we established)
  to be contributions of this work, and they are of course included in
  the mechanized code attached to the paper. We believe that people
  working on the verification of concurrent data structures in other
  languages or other verification frameworks could benefit from
  studying our proof arguments and, if they also use Iris, reusing our
  invariants and specifications -- just like we studied the existing
  Iris verifications of similar structures, typically in HeapLang.

> Emblematic of this problem is Section 4.1.1: This section give
> a history of various proposal for atomic fields with a full
> implementation timeline. However, at the end of the section it is
> unclear what the final implemented version actually is and what its
> formal semantics are. Similarly, the problem of physical equality is
> described well with many examples, but in a POPL paper I would expect
> a formal definition of physical equality, not just an informal
> description.

The section on physical equality was the hardest to write in the
paper. The difficulties around physical equality are subtle and easy
to misunderstand (we first had several experiences of failing to
explain them to domain experts), so they require ample informal
explanations.

We do include a precise definition (in English prose) of physical
equality on lines 765-777.

We would be happy to try to expand this section with a more formal
presentation of physical equality as done in our Rocq development, but
we must decide which part of the paper to remove
accordingly. (Any advice/preference on that end is welcome.)

> Also I would like to see how the proposal interacts with
> OCaml's weak memory model. Otherwise, it is impossible to understand
> what the authors concretely propose.

Our semantics for Zoo currently assume sequential consistency (as does
HeapLang and most other usable-in-practice Iris languages), so this
aspect of OCaml is not currently modeled in our work. (We mention this
explicitly in section 3.5.)

(We wonder if you were asking about interactions between physical
equality and OCaml's memory model. To our knowledge there are
essentially no interactions, as only mutable locations (atomic or
non-atomic) cause memory-model subtleties, and the difficulties we
found were centered on immutable constructors.

Structural equality does read sub-values under mutable locations, but
our program-logic require require either that immutable values are
being compared or that the caller uniquely owns their mutable parts,
so program that we can verify should not exhibit data races during
structural equality checking.)

> Also the description of the verified concurrent algorithms suffers
> from this problem: The text describes what the authors did at the
> high level, but does not provide technical detail on the novel
> insights. For example, the xchain assertion on l. 978 could be
> interesting, but is only mention in passing. Similar for the
> destabilization in Section 10.3.

We tried to summarize the salient points for domain experts, who are
welcome to look at the mechanized proofs for all the details. This
being said, we would be happy to receive recommendations from
reviewers on which technical points to expose more directly in the
article, and what part of the content should be removed to allow
this. Clearly it is impossible to hope to provide proof insights
and/or key invariants for all the structures we verified, but we could
cover just one for example in deeper levels of details.

> The authors develop ZooLang as a formalization of OCaml with
> a frontend for translating OCaml programs, but they do not discuss how
> ZooLang compares to OCaml. What features of OCaml does ZooLang support
> and which not?

We did try to exhaustively cover all supported Zoo features in Section
2.2, with a full grammar in Section 2. We support functions, including
recursive and mutually-recursive functions, integers (with arithmetic
and comparison operators), booleans (with if-then-else), for loops,
algebraic datatypes (variant/sums type, including constant and n-ary
constructors; and records, including mutable and atomic fields; and
records "inlined" within a variant constructor) but only shallow
pattern matching, and convenience syntax for references and lists. We
notably do not support the OCaml module system, but our translation
tool uses a mangling scheme for flat module hierarchies that appears
to suffice for now.

As we mentioned in the conclusion (lines 1220-1221), we believe that
the most pressing features to add for our problem domain would be:

- the OCaml memory model,

- exceptions (which are routinely used to signal failure), and

- effect handlers (which are typically not used to implement
  concurrent data structures, but are used in implementations of
  concurrent schedulers which we may want to verify).

> The authors claim that the HeapLang is the closest language to OCaml
> in the Iris ecosystem, but arguably state of the art of modeling OCaml
> is Osiris. I would like to see a more throughout comparison with
> Osiris.

Osiris and Zoo can be described as having evolved in two separate and complementary directions:

- Zoo has been designed from the start for pragmatic verification of advanced concurrent data-structures; this informed the choice of feature coverage and the semantics design. We succeeded in getting a practical verification framework for this domain, as evidenced by the vast amount of state-of-the-art examples we managed to verify.

- Osiris is designed to poke at the limits of language verification in general (not necessarily in a concurrent setting), and focused on order-of-evaluation issues and effect handlers as an advanced feature. On the other hand, the authors were only able to verify a small amount of relatively simple examples, suggesting that Osiris may not yet be ready for practical verification -- certainly not for our problem domain.

Osiris examples:
  https://gitlab.inria.fr/fpottier/osiris/-/blob/master/coq-osiris/examples/

For a concrete example of the difference in philosophy, the Osiris
designers ensured that they cover all possible evaluation orders for
OCaml, and in fact went above and beyond by supporting (sequential)
interleavings of argument evaluations, which is not allowed by the
informal OCaml specification. This is impressive, but it also makes
everyday proofs about n-ary functions more difficult. In contrast Zoo
makes the pragmatic choice of assuming a right-to-left evaluation
order for function arguments, which coincides with the choice of
existing OCaml compilers (ocamlc, ocamlopt, js_of_ocaml) and
simplifies verification. This means that the verified programs could
break under different OCaml implementations, but (1) so would various
OCaml programs in the wild, so new implementations tend to align with
this historical choice whenever possible, and (2) our aim is to verify
a finite amount of expert-level concurrent libraries that form basic
blocks of the ecosystem, and in our experience those programs do not
play games like passing two observably-effectful argument expressions
in a function call.

We did study our semantics tradeoffs carefully and made some 'perfectionist' rather than 'pragmatist' choices for language features that are essential to our problem domain, in particular atomic record fields and physical equality -- revealing potential issues in existing programs. Osiris is designed to be perfectionist for all aspects of the language it covers so it evolves at a slower pace; even with our personal involvement, it could probably not be equipped with concurrency-support features in a reasonable timeline for our verification work.

This does not mean of course that we cannot benefit from Osiris' study of OCaml semantics, and Osiris from ours. We believe that Osiris will be able to reuse many aspects our specification work when it adds support for physical equality. And in the future if Osiris gets within reaching distance of concurrent program verification, and economy of academic ressources suggests that merging the two efforts is the best route going forward, we could probably port our developments to this rule-them-all Iris language -- we have the experience of porting some of our developments from HeapLang to Zoo.

The same of course applies to HeapLang: we would be happy to contribute features back to HeapLang, and as a first step we would be delighted to contribute support for arbitrary sums/variants constructors instead of just `inL, inR` or `(tag, value)` encodings. Supporting constant and n-ary constructors would be nice, but the most impactful change would be the first step of supporting an arbitrary number of constructors with arbitrary names. We already started conversations in this direction, but modifying a widely-used (relatively speaking) verification language, whose maintainers already have a full plate of topics to work on, happens slowly and carefully.

> How does ZooLang handle exceptions and algebraic effects?

It does not. None of the data-structure we considered uses algebraic effects. (They are used in user-facing concurrency abstractions, such as `domainslib`.) We did encounter algorithms that raise exceptions (for example in our a-posteriori formalization of the Dynarray implementation; Dynarray raises in some failure scenarios that can only happen due to data races), and Zoo currently translates those failures into divergence, which is (not quite satisfying) but relatively standard Iris practice -- HeapLang does not have exceptions either.

> How does the physical equality of ZooLang compare to Osiris?

TODO (note: we mention lack of support for physical equality in Osiris above, to reformulate if this changed)

> Another relevant recent paper is "Data Race Freedom à la Mode"
> (POPL'25). How does Zoo compare to this paper? In particular, how does
> ZooLang compare to the language from this paper?

The language in that work is mostly an extension of HeapLang with
features (modalities and local regions) that are entirely orthogonal
to our work. It does not offer better support than HeapLang for the
features that we found essential theory (physical equality) or in
practice (non-encoded variant types, mutual recursion, atomic
operations on record fields rather than just references, etc.).

Note: the formalization of OCaml in that work assumes
a sequentially-consistent memory model, just like we do, providing
some support for the idea that it is reasonable to present scientific
contributions that are focused on concurrent OCaml programs without
quite going the full length of also handling weak memory
models. (This is of course not specific to this work and ours, the
vast majority of previous work on verification of concurrent data
structures in Iris have also been made under SC assumptions.) Most of
that work focuses on data-race-free programs, where the distinction
does not matter, but the key 'capsule' primitive API is implemented in
a less well-behaved language fragment, justified by semantic types in
a sequentially-consistent semantics. In particular, understanding
synchronization guarantees for capsules in a weak memory model would be
highly non-trivial, and was left as future work.

> Throughout the paper, the authors extensively refer to private
> discussions. It would be good to substantiate these claims with
> citations, e.g., to the relevant github issues, where possible.

As mentioned earlier, links to relevant github issues/PRs/RFCs are
available in our non-anonymous version of this paper.

> Also I would like to see less appeals to authority (e.g. on line 902
> to the recommendations of Thomas Leonard), but instead technical
> explanations why these case studies are interesting to verify.

More technical explanations are indeed desirable
(within space constraints). We do think that it is a reasonable
process to ask the main author and maintainer of an ambitious
concurrent OCaml library which parts they believe would benefit most
from a formalization effort, and focus on those parts first. The fact
that authors of key multicore OCaml libraries were able to get
rigorous feedback on their intuitions about concurrent subtleties and
correctness in their own code, within a reasonable time frame, is also
a secondary benefit of our effort.

> Did the authors try to upstream the generative attribute and if so,
> which feedback did they receive?
> 
> In Section 6, why does structural equality just imply physical
> equality and not Rocq-level equality?

Structural equality cannot in general imply Rocq-level equality, for
similar reasons to physical equality. For example, `Any false` and
`Any 0` may be both physically equal and structurally equal (in some
versions of the OCaml compiler), but they are represented by distinct
Rocq values.

In `Lemma structeq_spec_abstract`, the use of `val_physeq` is
unnecessarily confusing, and we should rephrase it. The idea is that
on deeply-immutable values (that are hereditarily formed of
immutable constructors), the guarantees we get from observing
structural or physical equality are exactly the same. `val_physeq`
states that the two values must have the same constructors and
immediate values at arbitrary depth (otherwise they would be
physically and structurally different), and `val_physneq` more
conservatively states that if the two values are immediate, then they
must be distinct, and if they are (mutable or)
immutable-but-generative constructors they must have a different
identity.

> The citation style of listing all authors is very verbose. I would
> recommend to use the standard citation style.
> 
> Minor comments:
> 
> l.93: "pointer quality" -> "pointer equality"
> 
> l.192: Please add references to the sections where the contributions
> can be found in the paper.
> 
> l.246: "include on tuples" -> "including on tuples"
> 
> l.254: "hey" -> "they"
> 
> l.732: Technically, it is not correct that if the CAS does not observe
> Open, it must be Closing since it could also be an Open with
> a different fd.
> 
> l.756: "th" -> "the"
> 
> Fig.4: The notation of triples using two lines is unusual and it took
> me quite a while to understand it. I would recommend to use the
> standard notation using curly braces.
> 
> l.1073: "arr" is unbound in the code. Maybe it should be "data"?
> 
> l.1142: "respecter" -> "respected"
> 
> Specific questions to be addressed in the author response
> ---------------------------------------------------------
> What features of OCaml does ZooLang support and which not?
> How does ZooLang handle exceptions and algebraic effects?
> How does the physical equality of ZooLang compare to Osiris?
> 
> How does Zoo compare to "Data Race Freedom à la Mode" (POPL'25)? In
> particular, how does ZooLang compare to the language from this paper?

(all these questions have been discussed above.)

> Review #427C
> ===========================================================================
> 
> Overall merit
> -------------
> B. OK paper, but I will not champion it
> 
> Reviewer expertise
> ------------------
> Z. Outsider
> 
> Paper summary
> -------------
> This paper presents a verification framework for concurrent OCaml
> programs in Rocq.  It consists of a core untyped language with an
> operational semantics equipped with an Iris program logic, and
> a translator from OCaml programs to Rocq representation in the core
> language.  The framework is used to verify data-structures from
> existing OCaml 5 libraries.  The paper also presents an extension to
> OCaml adding support for atomic record fields, and discuss subtleties
> regarding the treatment of physical equality, which is of particular
> importance when reasoning about concurrent programs using CAS.
> 
> **Strengths:**
> * design of an extension to OCaml that will allow existing codebase to
>   remove performance workarounds using unsafe idioms; and it is
>   expected to be released as part of OCaml 5.4 -- the paper give
>   a detailed description of the interaction with the OCaml community
>   and developers that resulted in this work.
> 
> * the paper highlights subtleties regarding the treatment of physical
>   equality, which is of particular importance when reasoning about
>   concurrent programs using CAS.  Even though they give
>   a specification tuned to OCaml, the presentation of section 5 should
>   be useful for future work on the formalisation of other languages.
> 
> **Weaknesses:**
> * the treatment of concurrency only supports an SC memory model, with
>   future support for weak behaviours planned based on the Cosmo
>   separation separation logic.
> 
> Comments for authors
> --------------------
> Is there a particular reason for defining a new Iris core language for
> OCaml, rather than trying to build on the Osiris work that you cite,
> by adding support to concurrency there?

One aspect to keep in mind is that the present submission represents several years of work. To understand this design choice, one cannot compare Zoo to the current state of Osiris as will presented in a few weeks at ICFP'25, but rather one should think of the state in which Osiris was a couple years ago.

(see our answer to Reviewer B for a more detailed technical and project-focus comparison with Osiris.)

> Doesn't the restriction to a SC memory model undermine the validity of
> the verification of the data-structures from Saturn, Eio, Picos you
> present in Section 10?

Yes, it does, as we discuss in Section 3.5 (lines 373-385). In
particular we wrote:

> Other algorithms do contain data races, and our formal correctness
> result must be taken with the caveat that it does not describe all
> observable behaviors in the actual OCaml program.

To our defense, the majority of published or in-progress work on verification of concurrent programs (including in OCaml) makes similar sequential-consistency assumptions.

Note that the recommended style for concurrent OCaml programs is to only use non-atomic locations for well-synchronized accesses (when we have unique ownership), and use the `Atomic` module (and now our atomic record fields) for all potentially-racy concurrent accesses. (This is encouraged in particular by the ThreadSanitizer (TSan) instrumentation for OCaml, which currently warns on all non-atomic races, with no way to disable them for races that are believed to be benign.)
Given that `Atomic` enforces a sequentially-consistent semantics, it may seem reasonable to assume that programs that respect this discipline only exhibit SC behaviors. Unfortunately the specialized libraries that we looked at, written by domain experts, do live dangerously and creatively combine atomic accesses with non-atomic accesses on different locations, making low-level assumptions about the semantics of memory fences generated by the compiler. This aspect of their work would certainly also benefit from a formalization effort.

(We also believe that it would be cleaner to add a notion of relaxed memory accesses to the OCaml memory model, rather than (ab)use non-atomic locations for benign races, if only to silence the TSan instrumentation. It is however non-trivial to extend the OCaml memory model with relaxed reads, and some of the OCaml maintainers are firmly opposed to making the memory model more complex.)


> ---
> 
> L702:  shouldn't the "close ()" instead be "Unix.close fd" ?

Indeed, this is a typo/confusion we introduced at the last minute, while editing the code to save some vertical space...

> **Editorial Comments**
> 
> L383:  verfication
> 
> L580:  owernship
> 
> L625:  *as* incorrect ?
> 
> L7656:  th
> 
> L1102:  correctly synchronization
> 
> L1143: protocol is respecter
> 
> L1154:  this paragraph starts strangely
> 
> L1208:  missing "equality"
