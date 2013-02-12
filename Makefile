%.tex: %.slides
	./convert_slides.pl $< > $@
%.pdf: %.tex
	pdflatex -shell-escape $<
