CONTENT_DIR=	public

TIDY?=		tidy

check:
	@rm -rf ${CONTENT_DIR}
	@hugo --destination=${CONTENT_DIR}
	@find ${CONTENT_DIR} -name "*.html" | while read f; do \
		${TIDY} \
			-quiet \
			-errors \
			--show-warnings yes \
			--show-filename yes \
			--mute-id yes \
			--mute TRIM_EMPTY_ELEMENT \
			--mute DISCARDING_UNEXPECTED \
			"$$f" || if [ $$? -gt 1 ]; then false; fi; \
	done
