pdf:=$(patsubst %.slides,build/%.pdf,$(wildcard *.slides))

all: build/$(basename $(shell ls -1t *.slides | head -1)).pdf
	evince $<

build/%.tex: %.slides
	@mkdir -p build
	python3 simple_beamer_slides.py < $< > $@

figures/%.pdf: figures/%.svg
	#inkscape -f $< -A $@
	inkscape --export-type 'pdf' $< --export-filename  $@

build/%.pdf: build/%.tex $(patsubst %.svg,%.pdf,$(wildcard figures/*.svg))
	@mkdir -p build
	ln -sf ../figures build/figures
	cp *.sty build/
#	xelatex -output-directory build -shell-escape $<
#	xelatex -output-directory build -shell-escape $<
	tectonic $< -o build -Z shell-escape

clean:
	rm -f build/*.{tex,aux,out,toc,log,nav,snm}
	rm -rf build/minted

.PRECIOUS: figures/%.pdf build/%.tex
