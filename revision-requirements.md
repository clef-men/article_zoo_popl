> - Provide a detailed mapping from the paper to the Rocq development (either in the artifact itself, or as part of the paper).

We did both:
- the paper is now full of Rocq icons that, when clicked, send you to the Rocq development.
- we also produced an artifact description at
    https://github.com/clef-men/zoo/blob/popl26/popl26.README.md
  which in particular details the paper-to-development mapping (in more details than just links)

> - Give a formal definition of the physical (dis)equality predicates in the paper

This is now done in Figure 4.

> - Replace references to private communication with links to PRs, issues, RFCs

This is now done, mostly via URLs in footnotes.
(We might have forgotten a few and will do another pass on this later on.)

> - Add a more detailed comparison with Osiris, ideally already early in the paper to avoid confusion about claims like that HeapLang is the closest language to OCaml in the Iris ecosystem
> - Add a comparison to DRFCaml. In particular, explain that DRFCaml distinguishes between non-atomic accesses and atomic accesses and how this compares to the accesses provided by Zoo.

We extended our Related Work section with discussion of HeapLang and DRFCaml.

(DRFCaml distinguishes atomic and non-atomic accesses, but it does not allow races on non-atomic locations. This is good if you can express your program in this fragment and prove that it is data-race free, but it does not let you express most efficient concurrent data-races as they are implemented in practice, with benign data races on non-atomic locations.)

> - Consider shrinking the discussion in Section 4.1 (but the full version can be included in an appendix)

We are planning to do this to go back within the 25 pages limit, but we ran a bit overtime with the other modifications and did not shrink much yet.

> - Mention the possibility of upstreaming [@generative] and other new features

We added a discussion of this in the Future Work section.

> - Provide a discussion of which features from OCaml are missing in ZooLang and how complex it would be to add them.

We added a discussion of this in the Future Work section. (We do not provide an exhaustive list of all OCaml features that are missing, because that would be way too long, but we list the big missing features and discuss them.)

We also moved our discussion of the sequential-consistency assumption there.
