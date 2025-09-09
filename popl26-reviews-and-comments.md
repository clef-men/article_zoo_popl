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

Our intent was to suggest, in a fact-based way, that getting features integrated in the upstream OCaml compiler is in fact a significant source of work.

> - Lines 600 - Lines 604: I think you should spell out the reason why
>   Some 0 == Some 0 can return false, for people who do not already
>   know why.
> 
> - Lines 618-620 -- but then doesn't the manual's described guarantee
>   contradict what's going on with the Any example in lines 594-599?
> 
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

Note that this is not just a matter of exposing explicitly a pointer indirection that exists in OCaml's data representation of sums/variants. The data representation in the HeapLang implementations we reviewed uses one *extra* pointer indirection for each element compared to a C or C++ (or Java, OCaml) implementation: one has to follow two pointers to go from a node to the value of the next node.

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

but this is not allowed due to the restricted semantics of compare-and-set: the HeapLang semantics allow calling compare-and-set on a value of type `UnboxedOption<Ref<...>>`, but *not* on a value of type `UnboxedOption<Pair<...>>` or `Pair<...>`.

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
> 
> 
> 
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
> 
> Emblematic of this problem is Section 4.1.1: This section give
> a history of various proposal for atomic fields with a full
> implementation timeline. However, at the end of the section it is
> unclear what the final implemented version actually is and what its
> formal semantics are.  Similarly, the problem of physical equality is
> described well with many examples, but in a POPL paper I would expect
> a formal definition of physical equality, not just an informal
> description. Also I would like to see how the proposal interacts with
> OCaml's weak memory model. Otherwise, it is impossible to understand
> what the authors concretely propose.  Also the description of the
> verified concurrent algorithms suffers from this problem: The text
> describes what the authors did at the high level, but does not provide
> technical detail on the novel insights. For example, the xchain
> assertion on l. 978 could be interesting, but is only mention in
> passing. Similar for the destabilization in Section 10.3.
> 
> The authors develop ZooLang as a formalization of OCaml with
> a frontend for translating OCaml programs, but they do not discuss how
> ZooLang compares to OCaml. What features of OCaml does ZooLang support
> and which not?
> The authors claim that the HeapLang is the closest language to OCaml
> in the Iris ecosystem, but arguably state of the art of modeling OCaml
> is Osiris. I would like to see a more throughout comparison with
> Osiris.
> How does ZooLang handle exceptions and algebraic effects?
> How does the physical equality of ZooLang compare to Osiris?

Osiris and Zoo can be described as having evolved in two separate and complementary directions:

- Zoo has been designed from the start for pragmatic verification of advanced concurrent data-structures; this informed the choice of feature coverage and the semantics design. We succeeded in getting a practical verification framework for this domain, as evidenced by the vast amount of state-of-the-art examples we managed to verify.

- Osiris is designed to poke at the limits of language verification in general (not necessarily in a concurrent setting), and focused on order-of-evaluation issues and effect handlers as an advanced feature. On the other hand, the authors were only able to verify a small amount of relatively simple examples, suggesting that Osiris may not yet be ready for practical verification -- certainly not for our problem domain.

Osiris examples:
  https://gitlab.inria.fr/fpottier/osiris/-/blob/master/coq-osiris/examples/

> Another relevant recent paper is "Data Race Freedom à la Mode"
> (POPL'25). How does Zoo compare to this paper? In particular, how does
> ZooLang compare to the language from this paper?
> 
> Throughout the paper, the authors extensively refer to private
> discussions. It would be good to substantiate these claims with
> citations, e.g., to the relevant github issues, where possible.  Also
> I would like to see less appeals to authority (e.g. on line 902 to the
> recommendations of Thomas Leonard), but instead technical explanations
> why these case studies are interesting to verify.
> 
> Did the authors try to upstream the generative attribute and if so,
> which feedback did they receive?
> 
> In Section 6, why does structural equality just imply physical
> equality and not Rocq-level equality?
> 
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
> 
> 
> 
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

One aspect to keep in mind is that the present submission represents several years of work. To understand this design choice, one cannot compare Zoo to the current state of Osiris as presented at ICFP'25, but rather to the state in which Osiris was a couple years ago.

TODO say more.

> Doesn't the restriction to a SC memory model undermine the validity of
> the verification of the data-structures from Saturn, Eio, Picos you
> present in Section 10?
> 
> ---
> 
> L702:  shouldn't the "close ()" instead be "Unix.close fd" ?
> 
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
