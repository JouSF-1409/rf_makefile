BINDIR=../bin/

SACHOME=/opt/sac

all: sachd sac_E sacMax iter_decon scc src_ss
	@if [ ! -d $(BINDIR) ]; then mkdir $(BINDIR); fi


sachd:sacio.c sachd.c
	gcc $^ -lm -o ${BINDIR}/sachd
sac_E:sac_e.c sacio.c
	gcc $^ -lm  -o ${BINDIR}/sac_e
sacMax:sacMax.c sacio.c
	gcc $^ -lm -o ${BINDIR}/sacMax
iter_decon:sacio.c Complex.c fft.c iter_decon.c
	gcc $^ -L$(SACHOME)/lib -lm -lsac -o ${BINDIR}/iter_decon -no-pie
scc:sacio.c scc.c
	gcc $^ -lm -o ${BINDIR}/scc
src_ss:sacio.c src_ss.c fft.c Complex.c
	gcc $^ -lm -o ${BINDIR}/src_ss
sacStack:sacio.c Complex.c fft.c sacStack.c
	gcc $^ -lm -o ${BINDIR}/$@

ccpStack3D: sacio.c ccpStack3D.c Complex.c fft.c
	gcc $^ -lm -o ${BINDIR}/$@;

clean:
	rm -r *.o ${BINDIR}/*
