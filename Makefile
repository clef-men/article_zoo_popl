LATEXMK=latexmk \
  -interaction=nonstopmode \
  -pdf -pdflatex="pdflatex --shell-escape %O %S" \
  -bibtex

.PHONY : all
all :
	$(LATEXMK) main.tex

.PHONY : watch
watch :
	$(LATEXMK) -pvc main.tex

.PHONY : clean
clean :
	git clean -fX

LATEXDIFF=latexdiff --allow-spaces --type=CCHANGEBAR --config "PICTUREENV=(?:(?:picture[\w\d*@]*)|(?:tikzpicture[\w\d*@]*)|(?:DIFnomarkup)|(?:mathpar)|(?:mathline)|(?:coqcode)|(?:ocamlcode)|(?:verbatim)|(?:tabular)|(?:figure)|(?:thebibliography))" --exclude-safecmd="ocaml" --exclude-safecmd="ocamlinline"

.PHONY : diff.tex
diff.tex :
	if [ ! -d old_version ] ; then git clone . old_version ; fi
	cd old_version ; git checkout old-version
	$(LATEXDIFF) ./old_version/main.tex main.tex --flatten > diff.tex

diff.pdf : diff.tex
	$(LATEXMK) diff.tex
