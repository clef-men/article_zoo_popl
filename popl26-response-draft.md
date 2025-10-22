We warmly thanks our reviewers for their effort in reviewing our work and the interesting feedback they sent us in return.

The question of comparing our work in more details to the Osiris verification framework (for a different fragment of OCaml) came up in several reviews, as well as a suggested comparison with DRFCaml from the "Data Race Freedom à la mode" POPL'25 paper. We discuss this *in details* below, at the risk of going over recommended lengths for an author response. (We have been in the opposite position of being reviewers during rebuttals, and in that position we do appreciate having more than two minutes of reading in response to a review that took more than a day to write, and may be our sole personal interaction with the work and its authors.) We will also discuss more specific comments from each review. Of course, please feel free to stop reading at any point, we tried to put the essential information first.

Before we go into these details, we would like to discuss the high-level / non-local changes to our presentation that have been suggested by reviewers.

- Review B remarks that too many technical details are elided from the paper. We do plan to provide a detailed mapping from the paper to the Rocq development which comes with it, but we are of course happy to try better integrating key technical contributions in the paper itself, if we can find content to remove or shrink accordingly.

   Review B suggests giving a formal definition of our physical (dis)equality predicates, in addition or replacement to our precise English prose description in lines 765-775. We are in favor of doing this.

   Review B also suggests giving more details on key definitions of invariants from our verified concurrent data structures. We suspect that the space required would be substantial and this sounds difficult, but we are happy to receive further guidance from our reviewers on content prioritization.
  
- There is probably a misunderstanding about "references to private communication", which we believe comes from the fact that we elided from our submission many public links to our work (PRs, issues, RFCs, etc.), due to the requirement for fully anonymous submissions. The non-anonymous version of our paper does include those links, references our (public and open-source) implementation and formalization, etc.


## Recent formalizations of fragments of OCaml: Osiris, DRFCaml

### Osiris

Our reviewers all asked for more discussions on the relation to Osiris, as published in
 https://cambium.inria.fr/~fpottier/publis/seassau-yoon-madiot-pottier-osiris-2025.pdf

> - Lines 1164 - 1167 : does Osiris have any advantages / different design decisions that are pertinent, other than the non-treatment of concurrency?

> The authors claim that the HeapLang is the closest language to OCaml in the Iris ecosystem, but arguably state of the art of modeling OCaml is Osiris. I would like to see a more throughout comparison with Osiris.

> Is there a particular reason for defining a new Iris core language for OCaml, rather than trying to build on the Osiris work that you cite, by adding support to concurrency there?

(On the last formulation from review C: one aspect to keep in mind is that the present submission represents several years of work. To understand our research methodology, one cannot compare Zoo to the current state of Osiris, as will be presented in a few weeks at ICFP'25, but rather one should think of the state in which Osiris was a couple years ago.)

Osiris and Zoo can be described as having evolved in two separate and complementary directions:

- Zoo has been designed from the start for pragmatic verification of advanced concurrent data-structures; this informed the choice of feature coverage and the semantics design. We succeeded in getting a practical verification framework for this domain, as evidenced by the substantial amount of state-of-the-art programs we managed to verify.

- Osiris is designed to poke at the limits of language verification in general (not necessarily in a concurrent setting), and focused on order-of-evaluation issues and effect handlers as an advanced feature. On the other hand, the authors verified a relatively small amount of simple examples¹, suggesting that Osiris may not yet be ready for practical verification at scale -- certainly not for our problem domain.

¹ https://gitlab.inria.fr/fpottier/osiris/-/blob/master/coq-osiris/examples/

For a concrete example of the difference in philosophy, the Osiris designers ensured that they cover all possible evaluation orders for OCaml, and in fact went above and beyond by supporting (sequential) interleavings of argument evaluations, which is not allowed by the informal OCaml specification. This is impressive, but it also makes everyday proofs about n-ary functions noticeably more difficult. In contrast Zoo makes the pragmatic choice of assuming a right-to-left evaluation order for function arguments, which coincides with the choice of all existing OCaml compilers (ocamlc, ocamlopt, `js_of_ocaml`) and simplifies verification. This means that the verified programs could break under different OCaml implementations, but (1) so would various OCaml programs in the wild, so new implementations tend to align with this historical choice whenever possible, and (2) our aim is to verify a finite amount of expert-level concurrent libraries that form basic blocks of the ecosystem, and in our experience those programs do not play dangerous games like passing two observably-effectful argument expressions in a function call -- not to suggest that they write particularly clean and easy-to-reason-about code, but they spend their complexity budget elsewhere.

(Note: HeapLang also uses right-to-left evaluation order for ergonomic reasons:  https://gitlab.mpi-sws.org/iris/iris/-/blob/c5014d246b2cc5d1bf79d3ba362501dd7b447f74/iris_heap_lang/lang.v#L12
)

We did study our semantics tradeoffs carefully and made some 'perfectionist' rather than 'pragmatist' choices for language features that are essential to our problem domain, in particular atomic record fields and physical equality -- revealing potential issues in existing programs. Osiris is designed to be perfectionist for all aspects of the language it covers so it evolves at a slower pace; even with our personal involvement, it could probably not be equipped with concurrency-support features in a reasonable timeline for our verification work. Finally, there is a risk that the resulting system would be less convenient to use in practice. This could have a substantial impact on the feasability of the verification effort, for these programs that are already close to the limit of the human comfort zone in dealing with complexity.

Having a simpler, more specialized system allowed us to cover more ground in term of actual real-world programs, and our scientific contributions come in part from this methodological choice.

This does not mean of course that we cannot benefit from Osiris' study of OCaml semantics, and Osiris from ours. We believe that Osiris will be able to reuse many aspects our specification work when it adds wider support for physical equality. And in the future if Osiris gets within reaching distance of concurrent program verification, and economy of academic ressources suggests that merging the two efforts is the best route going forward, we could probably port our developments to this rule-them-all Iris language -- we have the experience of porting some of our developments from HeapLang to Zoo.

The same applies to HeapLang: we would be happy to contribute features back to HeapLang, and as a first step we would be delighted to contribute support for arbitrary sums/variants constructors instead of just `inL, inR` or `(tag, value)` encodings. Supporting constant and n-ary constructors would be nice, but the most impactful change would be the first step of supporting an arbitrary number of constructors with arbitrary names. We already started conversations in this direction, but modifying a widely-used (relatively speaking) verification language, whose maintainers already have a full plate of topics to work on, happens slowly and carefully.


### DRFCaml

Review B also asks for a comparison to DRFCaml as published in

  https://iris-project.org/pdfs/2025-popl-drfcaml.pdf

> Another relevant recent paper is "Data Race Freedom à la Mode"
> (POPL'25). How does Zoo compare to this paper? In particular, how does
> ZooLang compare to the language from this paper?

Our understanding is that this language, DRFCaml, is mostly an extension of HeapLang with features (modalities and local regions) that are entirely orthogonal to our work. It does not offer better support than HeapLang for the features that we found essential in theory (physical equality) or in practice (non-encoded variant types, mutual recursion, etc.).

Note: DRFCaml also assumes a sequentially-consistent (SC) memory model, just like we do, providing some support for the idea that it is reasonable to present scientific contributions that are focused on concurrent OCaml programs without quite going the full length of also handling weak memory models. (This is of course not specific to this work and ours, the majority of previous work on verification of concurrent data structures in Iris have also been made under SC assumptions.) Most of the DRFCaml discussion focuses on data-race-free programs, where the distinction does not matter, but the key 'capsule' API is implemented in a less well-behaved language fragment, justified by semantic types in a sequentially-consistent semantics. In particular, we suspect that specifying and verifying synchronization guarantees for capsules in a weak memory model would be non-trivial, and was left as future work. This aligns with our research methodology of tackling the problems in a SC setting as a first step.


## Other review comments

### Review A

> - Section 3.2 -- after reading this, I understand the problem being
>   described, but I still didn't understand what solution you
>   selected. Perhaps you can describe the reduction rules?

This is a trick of proof engineering: technical and also a bit hard to explain... Suppose you have `let rec f = ... and g = ... in ...`. When we want to unfold the definition of `f` during reduction, we expand the body of `f` which contains (in the translated program) string variables `"f"` and `"g"`. At this point we do not want to substitute `"f"` and `"g"` with their definition, as this blows up in size, nor with `proj fg 0` and `proj fg 1` where `fg` would be the Coq identifier of the recursive group (and `proj` an operation that selects one of the recursive definitions), as this is less readable.

So we use the following machinery:

1. we define the whole recursive group, here `fg` (each definition comes with its name as a string, and refers to its own name recursively or other mutual names as strings),

2. we define convenience aliases `f` and `g` as these projections `proj fg 0` and `proj fg 1`; these are the names that user see.

   So far this is standard for mutual recursion. But At this point the expansion machinery could not guess that during unfolding, `"f"` should be translated into `f`, as `proj fg 0` does not carry any reference to the Coq values `f` and `g` (it would require a cyclic value as they are defined after `fg`). So there are more steps:

3. We use the typeclass machinery to declare a-posteriori and globally that `f` is our preferred abbreviation for the first projection of `fg`, and `g` for the second abbreviation of `fg`. Zoo defines typeclasses `AsValRecs` and `AsValRecs'`, and we register one instance per recursive function in the group, with information on (a) its position within the group, (b) the group iself, and (c) the list of all "preferred abbreviations" registered for this group.

4. Our reduction function on embedded Zoo program will query the typeclass database when reducing calls to some `proj fg i`: the code is substituted, and the embedded references to `"f"` and `"g"` in the code are replaced by direct references to the preferred abbreviations `f` and `g`, as found in the typeclass instance metadata.

(We suspect that it will be easier for designers of embedded languages to read our Rocq code than to try to reverse-engineer this from a detailed textual description we would include in the paper.)

> - Section 3.3 -- I get why SC makes it sound to translate
>   Atomic.get/Atomic.set to just loads/stores, but what I am confused
>   about is, does that mean you don't have "plain" references at all?
>   I.e. there's nothing that corresponds to the usual non-atomic "!"
>   operator in OCaml?

We translate ! like a normal load as well. (In the SC model there is no need to distinguish atomic from non-atomic accesses.)

> - Section 4.1 -- I don't think the full chronology of when things were implemented is really necessary/the best use of space.

Our intent was to suggest, in a fact-based way, that getting features integrated in the upstream OCaml compiler is in fact a significant source of work. (This is also a form of impact of our research, and show to our academic colleagues a bird's eye view of the dynamics involved could be of interest to some.)

Given the requests we received to add more content to the paper, we may favor shrinking this part or moving it to an appendix.

> - Lines 618-620 -- but then doesn't the manual's described guarantee
>   contradict what's going on with the Any example in lines 594-599?

OCaml implementations that validate the physical equality `Any false == Any 0` also validate the structural equality `Any false = Any 0`: structural equality in OCaml is implemented on untyped representations, and can relate values of different types.

> - Lines 948-951: I wouldn't really describe these as a "flaw" of those
>   stack examples, since using the pointers as they do makes them
>   closer to how those data structures are implemented in languages
>   like C or what you see in the algorithms papers describing those
>   examples. But you're absolutely right that it's not a good model of
>   an efficient/idiomatic OCaml implementation.

There are several ways to interpret this remark: "closer to C" could be in terms of programming style, or in term of data layout and in-memory representation. In this paragraph of our paper (and we expanded a bit on this in the specific case of the Michael-Scott queue afterwards), we emphasize that HeapLang programs have a *different* memory layout / data representation from textbook implementations in C/C++ (or Java, OCaml, etc.), due to the insertion of an *additional* pointer indirection in each node, which is specifically added to work around the restricted semantics of compare-and-swap in HeapLang.

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

For example `pop` first dereferences the mutable reference `s` and reads its value, then performs a second dereference on `l` when the stack is non-empty to be able to access the list cell, which is itself a (boxed) pair so a third dereference is implicit in `Fst "pair"` to get the first element of the list. (The Some constructor around `l` does not introduce a pointer indirection, as Heaplang assumes an optimized tagged encoding for disjoint sums constructor with a location payload.) See https://gitlab.mpi-sws.org/iris/iris/-/blob/c5014d246b2cc5d1bf79d3ba362501dd7b447f74/iris_heap_lang/lang.v#L148 for a documentation of the assumed HeapLang value representation.)

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

This program is morally correct, and it does correspond to the version that we verify in OCaml. But it is not a valid HeapLang program: the HeapLang semantics allow calling compare-and-set on a value of type `UnboxedOption<Ref<...>>`, but *not* on a value of type `UnboxedOption<Pair<...>>` (or `Pair<...>` for that matter).

We do believe that adding extra indirections in the memory layout, and corresponding allocations/dereferences in the implementation (adding noise to already-tricky code), is a "flaw" of the HeapLang implementations and verifications of these structures -- the implementation that is proved correct has a different computational behavior than the real-world implementation that we intend to verify, and expert authors of concurrent data structures would probably not accept to modify their code to match the verified implementation.
The change is relatively systematic, but also invasive. It makes them (less efficient and) more distant from the textbook implementations. See for example the textbook Java implementation on Wikipedia ( https://en.wikipedia.org/wiki/Treiber_stack ):

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


> 1. Can you say anything about whether your [@generative] directive
>    might be possibly merged, as your other proposed changes were? Or
>    are there drawbacks/design considerations that prevent that?

We have not started the upstreaming discussion yet. `[@generative]` is a much simpler change to implement than (say) atomic record fields, it suffices to ask the optimizer to pretend that the fields of the constructor are mutable instead of immutable. So we hope that it could be easier to gather consensus, and feel optimistic that it could be received positively by compiler maintainers.

(When we explained our justification for `[@generative]` to OCaml maintainers, they pointed an interesting potential use-case within the `Set` and `Map` module of the standard library. The `add` function in this module check the physical equality of its output with its input on recursive call into the relevant subtree, and in this case returns the larger input tree unchanged. The documentation states that the input is returned unchanged if the element is already in the set, but in fact this guarantee may be broken by unsharing, so one might want to add `[@generative]` to their data constructors to strengthen the guarantee.)

Our most substantial non-upstreamed change currently is the support for atomic arrays. It builds on top of the now-merged machinery for atomic record fields, so it is less invasive than atomic fields were. But it will require more review work and discussion than generative constructors:

- Example of non-scientific questions that will take some time to be discussed are: should this be an Atomic.Array submodule, or maybe an Array.Atomic submodule, or a first-level Atomic_Array module?  Should the new module export many helpful functions as the main Array module does, or just the bare primitives necessary to manipulate arrays in user code?

- On the more technical side, our patch introduces a new compiler primitive for array bound checking separately of array access (to be able to reuse it for atomic-array accesses; the OCaml backend uses a specific code-generation strategy to reduce code size for array bound accesses, and we would want to benefit from it as well), and we could expect some discussion with backend experts on the right/better way to do this.
  
- Some functions of the (non-atomic) Array module are implemented in C for efficiency reasons (`Array.blit`, `Array.sub`), reviewers could consider asking for the same effort on atomic arrays. On the other hand, it is unclear that these functions should be provided in the first place, as they would not operate atomically on their atomic array arguments.


### Review B

> - Many references to private communication

As mentioned in the introduction, most of these communications happened in public, but we had to hide the references to specific issues/PRs from the present submission as they would rather directly contradict the POPL instructions to carefully preserve anonymity. For example, we followed the standard *public* RFC process to discuss the design of Atomic record fields, and our local non-anonymous version of our paper of course links to our RFC and the following discussion, but providing this link to POPL reviewers would immediately de-anonymize some of the authors. When we cite specific individuals by name in our discussion of how the design evolved over time, it is to credit their contribution, not to suggest that we interacted in private.

We would of course link to those public discussions in a non-anonymous version of our work.

> On the surface, this seems like a very strong paper and with a solid
> technical contribution. However, the authors fail to present these
> impressive technical contributions in the paper.  The paper reads more
> like an experience report by the authors than a POPL paper describing
> the technical contributions.  When reading a POPL paper, I do not just
> expect reading what the authors did, but also to understand how the
> authors achieved their results, and what the insights are that are
> generally useful, even for people not directly working with OCaml.

One point to note in our defense is that the present submission is accompanied by an extensive Rocq development, which (we made available on submission on) intend to remain permanently linked to the paper, covering both the Zoo formalization and the various verified data-structures whose verification is claimed as a contribution. Any additional technical detail that would unfortunately be missing from the paper can be recovered (with some effort) from this mechanized development, which we believe follows reasonable standards of readability and maintenability.

This being said, we did try to emphasize some valuable lessons that reach outside the OCaml community:

- In section 3 we list salient language features that we encountered in concurrent OCaml code in practice, or in their verification, and in particular the centrality of physical equality. We would expect this to be relevant to people interested in verifying lock-free concurrent code in other functional languages such as Lisp/Scheme, Haskell, Scala, etc.

- The question of how to formalize physical equality similarly applies to all languages that offer composite/structured data structures with a mix of mutable and immutable constructors. (More precisely, immutable blocks without an identity.)

- We did not have the space to detail the verification arguments of the data-structures we verified, but we do consider their complete verification (and in particular the invariants that we established) to be contributions of this work, and they are of course included in the mechanized code attached to the paper. We believe that people working on the verification of concurrent data structures in other languages or other verification frameworks could benefit from studying our proof arguments and, if they also use Iris, reusing our invariants and specifications -- just like we studied the existing Iris verifications of similar structures, typically in HeapLang.
  
  We could plausibly extend our paper with de-Rocqified, in-greek descriptions of significant predicates and invariants, with a high-level commentary, in a supplementary appendix. But we do not know whether POPL editors would allow including appendices along with the paper. (The only related information we got so far is that any extra space would require transferring $200 from our research institutions to the ACM.)


> Emblematic of this problem is Section 4.1.1: This section give
> a history of various proposal for atomic fields with a full
> implementation timeline. However, at the end of the section it is
> unclear what the final implemented version actually is and what its
> formal semantics are. Similarly, the problem of physical equality is
> described well with many examples, but in a POPL paper I would expect
> a formal definition of physical equality, not just an informal
> description.

The section on physical equality was the hardest to write in the paper. The difficulties around physical equality are subtle and easy to misunderstand (we first had several experiences of failing to explain them to domain experts), so they require ample informal explanations.

We do include a precise definition (in English prose) of physical equality on lines 765-777.

We would be happy to try to expand this section with a more formal presentation of physical equality as done in our Rocq development, but we must decide which part of the paper to remove accordingly. (Any advice/preference on that end is welcome.)


> Also I would like to see how the proposal interacts with
> OCaml's weak memory model. Otherwise, it is impossible to understand
> what the authors concretely propose.

Our semantics for Zoo currently assume sequential consistency (as does HeapLang and most other usable-in-practice Iris languages), so this aspect of OCaml is not currently modeled in our work. (We mention this explicitly in section 3.5.)

We wonder if you were asking about interactions between physical equality and OCaml's memory model. To our knowledge there are essentially no interactions, as only mutable locations (atomic or non-atomic) cause memory-model subtleties, and the difficulties we found were centered on immutable constructors.

Structural equality does read sub-values under mutable locations, but our program-logic require require either that immutable values are being compared or that the caller uniquely owns their mutable parts, so program that we can verify should not exhibit data races during structural equality checking.

> Also the description of the verified concurrent algorithms suffers
> from this problem: The text describes what the authors did at the
> high level, but does not provide technical detail on the novel
> insights. For example, the xchain assertion on l. 978 could be
> interesting, but is only mention in passing. Similar for the
> destabilization in Section 10.3.

We tried to summarize the salient points for domain experts, who are welcome to look at the mechanized proofs for all the details. This being said, we would be happy to receive recommendations from reviewers on which technical points to expose more directly in the article, and what part of the content should be removed to allow this. Clearly it is difficult to hope to provide proof insights and/or key invariants for all the structures we verified, but we could cover just one for example in deeper levels of details.

> The authors develop ZooLang as a formalization of OCaml with
> a frontend for translating OCaml programs, but they do not discuss how
> ZooLang compares to OCaml. What features of OCaml does ZooLang support
> and which not?

We did try to exhaustively cover all supported Zoo features in Section 2.2, with a full grammar in Section 2. We support functions, including recursive and mutually-recursive functions, integers (with arithmetic and comparison operators), booleans (with if-then-else), for loops, algebraic datatypes (variant/sums type, including constant and n-ary constructors; and records, including mutable and atomic fields; and records "inlined" within a variant constructor) but only shallow pattern matching, and convenience syntax for references and lists. We notably do not support the OCaml module system, but our translation tool uses a mangling scheme for flat module hierarchies that appears to suffice for now.

As we mentioned in the conclusion (lines 1220-1221), we believe that the most impactful features to add for our problem domain would be:

- the OCaml weak memory model,

- exceptions (which are routinely used to signal failure), and

- effect handlers with one-shot continuations (which are typically not used to implement concurrent data structures, but are used in implementations of concurrent schedulers which we may want to verify)


> How does ZooLang handle exceptions and algebraic effects?

It does not. None of the data-structure we considered uses algebraic effects. (They are used in user-facing concurrency abstractions, such as `domainslib`.) We did encounter algorithms that raise exceptions (for example in our a-posteriori formalization of the Dynarray implementation; Dynarray raises in some failure scenarios that can only happen due to data races), and Zoo currently translates those failures into divergence, which is (not quite satisfying) but relatively standard Iris practice -- HeapLang does not have exceptions either.

> How does the physical equality of ZooLang compare to Osiris?

Osiris currently only supports physical-equality checks between
references and continuations. There is no physical-equality between
pure constructors (or records, integers, strings, arrays, etc.):

References:
- physical equality: https://gitlab.inria.fr/fpottier/osiris/-/blob/89cf70870fa52b92d61e828bdfd0831dafa04ae9/coq-osiris/theories/semantics/eval.v#L586
- value representation: https://gitlab.inria.fr/fpottier/osiris/-/blob/89cf70870fa52b92d61e828bdfd0831dafa04ae9/coq-osiris/theories/lang/syntax.v#L372


> Also I would like to see less appeals to authority (e.g. on line 902
> to the recommendations of Thomas Leonard), but instead technical
> explanations why these case studies are interesting to verify.

More technical explanations are indeed desirable (within space constraints). We do think that it is a reasonable process to ask the main author and maintainer of an ambitious concurrent OCaml library which parts they believe would benefit most from a formalization effort, and focus on those parts first. The fact that authors of key multicore OCaml libraries were able to get rigorous feedback on their intuitions about concurrent subtleties and correctness in their own code, within a reasonable time frame, is also a secondary benefit of our effort.

> Did the authors try to upstream the generative attribute and if so, which feedback did they receive?

We discuss this in the section dedicated to review A above.

> In Section 6, why does structural equality just imply physical
> equality and not Rocq-level equality?

Structural equality cannot in general imply Rocq-level equality, for similar reasons to physical equality. For example, `Any false` and `Any 0` may be both physically equal and structurally equal (in some versions of the OCaml compiler), but they are represented by distinct Rocq values.

In `Lemma structeq_spec_abstract`, the use of `val_physeq` is unnecessarily confusing, and we should rephrase it. The idea is that on deeply-immutable values (that are hereditarily formed of immutable constructors), the guarantees we get from observing structural or physical equality are exactly the same. `val_physeq` states that the two values must have the same constructors and immediate values at arbitrary depth (otherwise they would be physically and structurally different), and `val_physneq` more conservatively states that if the two values are immediate, then they must be distinct, and if they are (mutable or) immutable-but-generative constructors they must have a different identity.


> l.732: Technically, it is not correct that if the CAS does not observe
> Open, it must be Closing since it could also be an Open with
> a different fd.

The protocol for this part of the state is that Open transitions to Closing, but never to another Open. As our proof shows, the only possible values here are the Open we observed or a Closing. (The problem comes from the fact that the Open we observed is *not* necessarily equal to itself, in presence of unsharing.)


### Review C

> Doesn't the restriction to a SC memory model undermine the validity of
> the verification of the data-structures from Saturn, Eio, Picos you
> present in Section 10?

Yes, it does, as we discuss in Section 3.5 (lines 373-385). In
particular we wrote:

> Other algorithms do contain data races, and our formal correctness
> result must be taken with the caveat that it does not describe all
> observable behaviors in the actual OCaml program.

To our defense, a majority of published or in-progress work on verification of concurrent programs (including in OCaml) makes similar sequential-consistency assumptions.

Note that the recommended style for concurrent OCaml programs is to only use non-atomic locations for well-synchronized accesses (when we have unique ownership), and use the `Atomic` module (and now our atomic record fields) for all potentially-racy concurrent accesses. (This is encouraged in particular by the ThreadSanitizer (TSan) instrumentation for OCaml, which currently warns on all non-atomic races, with no way to disable them for races that are believed to be benign.)
Given that `Atomic` references enforce a sequentially-consistent semantics, it may seem reasonable to assume that programs that respect this discipline only exhibit SC behaviors. Unfortunately several of the specialized libraries that we looked at, written by domain experts, do live dangerously and creatively combine atomic accesses with non-atomic accesses on different locations, making low-level assumptions about the semantics of memory fences generated by the compiler. This aspect of their work would certainly also benefit from a formalization effort.

(We also believe that it would be cleaner to add a notion of relaxed memory accesses to the OCaml memory model, rather than (ab)use non-atomic locations for benign races, if only to silence the TSan instrumentation. It is however non-trivial to extend the OCaml memory model with relaxed reads, and some of the OCaml maintainers are understandably opposed to making the memory model more complex.)

Note that moving to weaker memory model would not throw our work away, it would extend it. The weak-memory-model specifications are more complex, and the proofs are more complex, but they are obtained by refining the SC specifications and invariants. Our work thus provides a first (highly non-trivial) step in this direction.

> L702:  shouldn't the "close ()" instead be "Unix.close fd" ?

Indeed, this is a typo/confusion we introduced at the last minute, while editing the code to save some vertical space...
