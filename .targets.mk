# draft-hardt-aauth-bootstrap draft-hardt-aauth-events draft-hardt-aauth-r3 draft-hardt-oauth-aauth-protocol 
# draft-hardt-aauth-bootstrap-00 draft-hardt-aauth-bootstrap-01 draft-hardt-aauth-headers-00 draft-hardt-aauth-headers-01 draft-hardt-aauth-protocol-00 draft-hardt-aauth-protocol-01 draft-hardt-aauth-protocol-02 draft-hardt-oauth-aauth-protocol-00 draft-hardt-oauth-aauth-protocol-01 draft-hardt-oauth-aauth-protocol-02 draft-hardt-oauth-aauth-protocol-03 draft-hardt-oauth-aauth-protocol-04 draft-hardt-oauth-aauth-protocol-05 draft-hardt-oauth-aauth-protocol-06 draft-hardt-oauth-aauth-protocol-07 draft-hardt-oauth-aauth-protocol-08 draft-hardt-oauth-aauth-protocol-09
versioned:
	@mkdir -p $@
.INTERMEDIATE: versioned/draft-hardt-aauth-bootstrap-00.md
.SECONDARY: versioned/draft-hardt-aauth-bootstrap-00.xml
versioned/draft-hardt-aauth-bootstrap-00.md: | versioned
	git show "draft-hardt-aauth-bootstrap-00:draft-hardt-aauth-bootstrap.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-04-29/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-00/g' -e 's/draft-hardt-aauth-protocol-date/2026-04-13/g' -e 's/draft-hardt-aauth-protocol-latest/draft-hardt-aauth-protocol-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-aauth-bootstrap-00\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-aauth-bootstrap-00" "draft-hardt-aauth-bootstrap-00" "$@"
.INTERMEDIATE: versioned/draft-hardt-aauth-bootstrap-01.md
.SECONDARY: versioned/draft-hardt-aauth-bootstrap-01.xml
versioned/draft-hardt-aauth-bootstrap-01.md: | versioned
	git show "draft-hardt-aauth-bootstrap-01:draft-hardt-aauth-bootstrap.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-05-06/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-01/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-aauth-bootstrap-01\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-aauth-bootstrap-01" "draft-hardt-aauth-bootstrap-01" "$@"
.INTERMEDIATE: versioned/draft-hardt-aauth-bootstrap-02.md
versioned/draft-hardt-aauth-bootstrap-02.md: draft-hardt-aauth-bootstrap.md | versioned
	sed -e 's/draft-hardt-aauth-bootstrap-date/2026-07-05/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-02/g' -e 's/draft-hardt-aauth-events-date/2026-07-05/g' -e 's/draft-hardt-aauth-events-latest/draft-hardt-aauth-events-00/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-07-05/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-10/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-aauth-bootstrap-02\//; }' $< >$@
	$(LIBDIR)/make-includes.sh "HEAD" "draft-hardt-aauth-bootstrap-02" "$@"
diff-draft-hardt-aauth-bootstrap.html: versioned/draft-hardt-aauth-bootstrap-01.txt versioned/draft-hardt-aauth-bootstrap-02.txt
	-$(iddiff) $^ > $@
.INTERMEDIATE: versioned/draft-hardt-aauth-events-00.md
versioned/draft-hardt-aauth-events-00.md: draft-hardt-aauth-events.md | versioned
	sed -e 's/draft-hardt-aauth-bootstrap-date/2026-07-05/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-02/g' -e 's/draft-hardt-aauth-events-date/2026-07-05/g' -e 's/draft-hardt-aauth-events-latest/draft-hardt-aauth-events-00/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-07-05/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-10/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-aauth-events-00\//; }' $< >$@
	$(LIBDIR)/make-includes.sh "HEAD" "draft-hardt-aauth-events-00" "$@"
.INTERMEDIATE: versioned/draft-hardt-aauth-r3-00.md
versioned/draft-hardt-aauth-r3-00.md: draft-hardt-aauth-r3.md | versioned
	sed -e 's/draft-hardt-aauth-bootstrap-date/2026-07-05/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-02/g' -e 's/draft-hardt-aauth-events-date/2026-07-05/g' -e 's/draft-hardt-aauth-events-latest/draft-hardt-aauth-events-00/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-07-05/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-10/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-aauth-r3-00\//; }' $< >$@
	$(LIBDIR)/make-includes.sh "HEAD" "draft-hardt-aauth-r3-00" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-00.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-00.xml
versioned/draft-hardt-oauth-aauth-protocol-00.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-00:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-04-29/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-00/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-04-29/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-00/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-00\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-00" "draft-hardt-oauth-aauth-protocol-00" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-01.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-01.xml
versioned/draft-hardt-oauth-aauth-protocol-01.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-01:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-05-06/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-01/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-01\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-01" "draft-hardt-oauth-aauth-protocol-01" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-02.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-02.xml
versioned/draft-hardt-oauth-aauth-protocol-02.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-02:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-06-09/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-02/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-02\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-02" "draft-hardt-oauth-aauth-protocol-02" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-03.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-03.xml
versioned/draft-hardt-oauth-aauth-protocol-03.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-03:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-06-15/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-03/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-03\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-03" "draft-hardt-oauth-aauth-protocol-03" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-04.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-04.xml
versioned/draft-hardt-oauth-aauth-protocol-04.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-04:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-06-15/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-04/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-04\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-04" "draft-hardt-oauth-aauth-protocol-04" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-05.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-05.xml
versioned/draft-hardt-oauth-aauth-protocol-05.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-05:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-06-15/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-05/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-05\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-05" "draft-hardt-oauth-aauth-protocol-05" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-06.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-06.xml
versioned/draft-hardt-oauth-aauth-protocol-06.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-06:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-06-17/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-06/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-06\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-06" "draft-hardt-oauth-aauth-protocol-06" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-07.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-07.xml
versioned/draft-hardt-oauth-aauth-protocol-07.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-07:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-06-17/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-07/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-07\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-07" "draft-hardt-oauth-aauth-protocol-07" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-08.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-08.xml
versioned/draft-hardt-oauth-aauth-protocol-08.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-08:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-06-25/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-08/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-08\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-08" "draft-hardt-oauth-aauth-protocol-08" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-09.md
.SECONDARY: versioned/draft-hardt-oauth-aauth-protocol-09.xml
versioned/draft-hardt-oauth-aauth-protocol-09.md: | versioned
	git show "draft-hardt-oauth-aauth-protocol-09:draft-hardt-oauth-aauth-protocol.md" | sed -e 's/draft-hardt-aauth-bootstrap-date/2026-05-06/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-01/g' -e 's/draft-hardt-aauth-events-date/2026-07-05/g' -e 's/draft-hardt-aauth-events-latest/draft-hardt-aauth-events-00/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-07-05/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-09/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-09\//; }' >$@
	$(LIBDIR)/make-includes.sh "draft-hardt-oauth-aauth-protocol-09" "draft-hardt-oauth-aauth-protocol-09" "$@"
.INTERMEDIATE: versioned/draft-hardt-oauth-aauth-protocol-10.md
versioned/draft-hardt-oauth-aauth-protocol-10.md: draft-hardt-oauth-aauth-protocol.md | versioned
	sed -e 's/draft-hardt-aauth-bootstrap-date/2026-07-05/g' -e 's/draft-hardt-aauth-bootstrap-latest/draft-hardt-aauth-bootstrap-02/g' -e 's/draft-hardt-aauth-events-date/2026-07-05/g' -e 's/draft-hardt-aauth-events-latest/draft-hardt-aauth-events-00/g' -e 's/draft-hardt-aauth-r3-date/2026-07-05/g' -e 's/draft-hardt-aauth-r3-latest/draft-hardt-aauth-r3-00/g' -e 's/draft-hardt-oauth-aauth-protocol-date/2026-07-05/g' -e 's/draft-hardt-oauth-aauth-protocol-latest/draft-hardt-oauth-aauth-protocol-10/g' -e '/^{::include [^\/]/{ s/^{::include /{::include versioned\/draft-hardt-oauth-aauth-protocol-10\//; }' $< >$@
	$(LIBDIR)/make-includes.sh "HEAD" "draft-hardt-oauth-aauth-protocol-10" "$@"
diff-draft-hardt-oauth-aauth-protocol.html: versioned/draft-hardt-oauth-aauth-protocol-09.txt versioned/draft-hardt-oauth-aauth-protocol-10.txt
	-$(iddiff) $^ > $@
