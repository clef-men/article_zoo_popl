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
